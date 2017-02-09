#! /usr/bin/python
"""This library will manage files stored in google cloud storage.
Since many files are produced when clusters are created, we need
to retain them so we can use them across container instances.
"""
import os
import sys
import re

import argparse

from google.cloud import storage

GOOGLE_APPLICATION_CREDENTIALS = 'GOOGLE_APPLICATION_CREDENTIALS'
CLUSTER_NAME = 'CLUSTER_NAME'
CLOUD_STORAGE = 'CLOUD_STORAGE'


def main():
    """Parse command line and run the appropriate method"""
    parser = argparse.ArgumentParser()
    parser.add_argument('--upload', action='store_true', help='Upload cluster config files to cloud storage')
    parser.add_argument('--download', action='store_true', help='Download cluster config files from cloud')
    parser.add_argument('--clean', action='store_true', help='Remove cluster config files from cloud')

    if len(sys.argv) != 2:
        parser.print_help()
        sys.exit(1)

    try:
        options = parser.parse_args()
    except:
        parser.print_help()
        sys.exit(0)

    cs = CloudStorage.factory()
    if options.upload:
        cs.upload()

    elif options.download:
        cs.download()

    elif options.clean:
        cs.clean()

    else:
        # should never get here...
        parser.print_help()
        sys.exit(1)


class CloudStorage(object):
    """Factory class for CloudStorage"""

    def factory():
        """GCS or K8 types"""

        # If this is set, use a bucket, otherwise use k8 secret
        storage_type = os.environ.get(CLOUD_STORAGE)
        if storage_type:
            return GCSCloudStorage()

        return K8CloudStorage()

    factory = staticmethod(factory)

    @staticmethod
    def _print_err(msg):
        print 'ERROR: {}'.format(msg)
        exit(1)

    @staticmethod
    def _print(msg):
        print 'STORAGE: {}'.format(msg)


class K8CloudStorage(CloudStorage):
    """Store zip of config files in kubernetes"""

    def __init__(self):
        if not os.path.isfile('phase1/gce/.tmp/kubeconfig.json'):
            self._print_err('Missing phase1/gce/.tmp/kubeconfig.json file')

        self.kubectl = 'kubectl --kubeconfig=phase1/gce/.tmp/kubeconfig.json --namespace=kube-system'

    def _run(self, cmd):
        result = os.system(cmd)
        if result:
            self._print_err('Command failed: {}'.format(cmd))
            print 'ERROR: '

    def upload(self):
        """Zip files, then upload to k8-anywhere-configs secret"""
        cmd = """zip configs.zip .config* phase1/gce/terraform.tfstate* phase1/gce/.tmp/* && \
            {} create secret generic k8-anywhere-configs --from-file=zip=configs.zip && \
            rm configs.zip""".format(self.kubectl)
        self._run(cmd)

    def download(self):
        """Fetch and unpack the k8-anywhere-configs secret"""
        cmd = """{} get secret k8-anywhere-configs -o json | \
            jq -r '.data.zip' | \
            base64 -d > configs.zip && \
            unzip -o configs.zip && \
            rm configs.zip""".format(self.kubectl)
        self._run(cmd)

    def clean(self):
        """This method doesn't do anything. The cluster where the configs live is gone..."""
        self._print('Nothing to clean...')


class GCSCloudStorage(CloudStorage):
    """Use this class to send files up or get files from google cloud storage"""

    def __init__(self):
        self.cwd = os.path.dirname(os.path.realpath(__file__))
        self.tmp = '{}/.tmp'.format(self.cwd)
        self.root = self.cwd.replace('/phase1/gce', '')

        # We make sure the GOOGLE_APPLICATION_CREDENTIALS env var is set.
        # If it is not, we set it to self.cwd/account.json
        credentials = os.environ.get(GOOGLE_APPLICATION_CREDENTIALS)
        if not credentials:
            account_json = '{}/account.json'.format(self.cwd)
            if os.path.isfile(account_json):
                os.environ[GOOGLE_APPLICATION_CREDENTIALS] = account_json
                self._print('Loading creds from {}'.format(account_json))
            else:
                msg = 'Missing Environment Variable {} and default file {} not found'.format(
                    GOOGLE_APPLICATION_CREDENTIALS, account_json)
                self._print_err(msg)

        self.storage_client = storage.Client()
        if not self.storage_client:
            self._print_err('Could not get google cloud storage client')

        # verify that the ENV for cluster_name is set. We use that for folder.
        cluster_name = os.environ.get(CLUSTER_NAME)
        if not cluster_name:
            self._print_err('Missing env var {}'.format(CLUSTER_NAME))
        self.cluster_name = self._cleanse_name(cluster_name)

        self.bucket = self._get_bucket()

    def _get_bucket(self):
        """The bucket name should be <project>-applariat-cluster-data.
        A '.' cannot be used in the name or it will require proper DNS."""

        project = self._cleanse_name(self.storage_client.project)
        bucket_name = '{}-k8-anywhere-cluster-data'.format(project)

        bucket = self.storage_client.lookup_bucket(bucket_name)
        if not bucket:
            bucket = self.storage_client.create_bucket(bucket_name)
            self._print('Bucket {} created.'.format(bucket.name))
        else:
            self._print('Bucket {} found.'.format(bucket.name))

        return bucket

    def _upload_blob(self, file):
        """Uploads a file to the bucket. Use the cluster_name as folder"""
        source_file_name = '{}/{}'.format(self.root, file)
        destination_name = '{}/{}'.format(self.cluster_name, file)
        blob = self.bucket.blob(destination_name)
        blob.upload_from_filename(source_file_name)

        self._print('Uploading {} -> {}/{}'.format(source_file_name, self.bucket.name, destination_name))

    @staticmethod
    def _cleanse_name(name):
        """Allow only num/char/-/_ in names. Periods will be removed due to DNS issue"""
        return re.sub(r'^[a-zA-Z0-9-_]$', '', name)

    def upload(self):
        """Upload all required files"""

        # root files
        self._upload_blob('.config')
        self._upload_blob('.config.json')

        # phase1/gce files
        self._upload_blob('phase1/gce/terraform.tfstate')
        self._upload_blob('phase1/gce/terraform.tfstate.backup')

        # phase1/gce/.tmp files, some names are generated so it is easier to loop
        for _, _, tmp_files in os.walk(self.tmp):
            for tmp_file in tmp_files:
                f = '{}/{}'.format('phase1/gce/.tmp', tmp_file)
                self._upload_blob(f)

    def download(self):
        """Downloads all files to local system. Puts them where they belong"""

        if not os.path.exists(self.tmp):
            os.makedirs(self.tmp)

        blobs = self.bucket.list_blobs(prefix=self.cluster_name)
        for blob in blobs:
            # Need to replace cluster_name folder with cwd
            destination_file_name = blob.name.replace(self.cluster_name, self.root, 1)
            blob.download_to_filename(destination_file_name)
            self._print('Downloaded {}'.format(destination_file_name))

    def clean(self):
        """Remove the folder that contains all cluster information"""

        blobs = self.bucket.list_blobs(prefix=self.cluster_name)
        for blob in blobs:
            self._print('Deleting {}/{}'.format(self.bucket.name, blob.name))
            self.bucket.delete_blob(blob.name)


if __name__ == '__main__':
    main()
