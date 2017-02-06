"""
This will print the contents of the
"""
import os


def main():
    """Set up ENV vars needed and call EnvConfig.run()"""
    # used to prefix vars in .config file. Default is 'CONFIG_', so we use '.' instead.
    os.environ['CONFIG_'] = '.'

    # This is the only pre-defined var that is required
    # This var triggers an env config to fire in the Makefile
    CLOUD_PROVIDER = os.environ.get('CLOUD_PROVIDER')

    if not CLOUD_PROVIDER:
        print 'ERROR: Missing Environment Variable CLOUD_PROVIDER'
        exit(1)
