name             'cloudops_win_2016'
maintainer       'Adobe Systems, Inc.'
maintainer_email 'prsinha@adobe.com'
license          'All rights reserved'
description      'Installs/Configures cloudops_win_2016'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'

depends 'chocolatey'
depends 'hubble', '~> 0.8.1'
depends 'co-awsazurecli'