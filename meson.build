# Project name, programming language and version
project (
    'io.github.jhaygood86.big-purple-remote',
    'vala', 'c',
    version: '0.1.0',
    meson_version: '>= 0.50.0',
    default_options: [
        'warning_level=2',
    ],
)

# Translation module
i18n = import ('i18n')

# GNOME module
gnome = import ('gnome')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

# Compiling resources
asresources = gnome.compile_resources (
    'as-resources',
    join_paths ('data', meson.project_name ()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)


# Listing dependencies
dependencies = [
    dependency ('gobject-2.0'),
    dependency ('gtk+-3.0'),
    dependency ('libhandy-1', version: '>=0.90.0'),
    dependency ('granite', version: '>=6.0.0'),
    dependency ('gee-0.8'),
    dependency ('libsoup-2.4', version: '>= 2.62'),
    dependency ('gssdp-1.2', version: '>= 1.0.0'),
    dependency ('gupnp-1.2', version: '>= 1.0.0'),
    dependency ('gxml-0.20')
]

subdir ('src')

# Defining executable
executable (
    meson.project_name (),
    sources,
    asresources,
    dependencies: dependencies,
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
