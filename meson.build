project('io.github.jhaygood86.big-purple-remote', ['c', 'vala'],
          version: '0.1.1',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

bigpurpleremote_res = gnome.compile_resources(
    'bigpurpleremote-resources',
    join_paths('data', 'gresource.xml'),
    source_dir: 'data'
)

bigpurpleremote_deps = [
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    dependency('libhandy-1', version: '>=0.90.0'),
    dependency('granite', version: '>=6.0.0'),
    dependency('gee-0.8'),
    dependency('libsoup-2.4', version: '>= 2.62'),
    dependency('gssdp-1.2', version: '>= 1.0.0'),
    dependency('gupnp-1.2', version: '>= 1.0.0'),
    dependency('gxml-0.20')
]

executable(
    meson.project_name(),
    bigpurpleremote_res,
    config_file,
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/RokuDevice.vala',
    'src/RokuManager.vala',
    'src/Widgets/RemoteGrid.vala',
    dependencies: bigpurpleremote_deps,
    install: true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
