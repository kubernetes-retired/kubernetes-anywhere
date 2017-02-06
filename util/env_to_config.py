#!/usr/bin/python
"""
Used to convert ENV vars into a .config file. This will prevent the system from prompting for values.
The Kconfig files will be parsed to determine what vars to check for, their default values and their types.
A detailed error message should be produced that describes all vars that can be set and/or errors.
"""
import os
import kconfiglib as kc


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

    ec = EnvConfig(cloud_provider=CLOUD_PROVIDER)
    ec.run()


class EnvConfig(object):
    """Class to create .config file from ENV vars"""

    def __init__(self, cloud_provider):
        self.cloud_provider = cloud_provider
        self.cloud_config = 'phase1/{}/Kconfig'.format(self.cloud_provider)
        self.conf = kc.Config()
        self.print_config = True

    @staticmethod
    def _print_err(key, val, name, msg):
        print 'ERR[{}] {}="{}" ({})'.format(name, key, val, msg)

    @staticmethod
    def _print_env(key, val, name, msg='ok'):
        print 'ENV[{}] {}="{}" ({})'.format(name, key, val, msg)

    def _set_symbol_from_env(self, symbol):
        """Examine the symbol, set value from env var and print debug"""
        name = symbol.get_name()
        val = symbol.get_value()
        env_key = name[name.find('.') + 1:].replace('.', '_').upper()
        env_val = os.environ.get(env_key)

        if env_val:
            # We have found a valid ENV value, override
            try:
                symbol.set_user_value(env_val)
                self._print_env(env_key, env_val, name)
            except:
                # Error assigning value. Don't write .config
                self.print_config = False
                self._print_err(env_key, env_val, name, 'problem assigning value, check logs for more info')
        else:
            # No env var found, check to see if there is a default.
            if val != '' or symbol.def_exprs:
                self._print_env(env_key, val, name, 'env var missing, using default')
            else:
                self.print_config = False
                self._print_err(env_key, val, name, 'missing required env var, no default found')

    def run(self):
        """This is the entrypoint and handles the traversing of the Kconfig data"""
        for item in self.conf.get_top_level_items():
            # These are top level menus
            if item.filename.startswith('phase1'):
                # Proccess phase1
                # handle all symbols first so that the variables used in menus are set
                for s in item.get_items():
                    if s.is_symbol():
                        # print "config {0}".format(s.get_name())
                        self._set_symbol_from_env(s)

                # Next, menu items.
                for m in item.get_items():
                    if m.is_menu():
                        if m.filename == self.cloud_config:
                            # This means the filename matched the cloud config file, such as gce
                            # This is handled differently than other phases because it has sub files.
                            # Other phases don't have sub files, just one top level
                            for s2 in m.get_items():
                                if s2.is_symbol():
                                    self._set_symbol_from_env(s2)
                        else:
                            # This means it is not a phase1/cloud_provider we include in the final .config
                            m.write_to_conf = False

            else:
                # process phases that don't have sub dirs i.e. cloud_providers
                for s in item.get_items():
                    if s.is_symbol():
                        self._set_symbol_from_env(s)

        if self.print_config:
            self.conf.write_config('.config')
        else:
            exit(1)


if __name__ == "__main__":
    main()
