include_recipe "pivotal_server::imagemagick"
include_recipe "pivotal_server::postgres"
include_recipe "pivotal_server::sqlite"
include_recipe "pivotal_server::libxml_prereqs"
include_recipe "pivotal_server::nginx"
include_recipe "pivotal_ci::id_rsa"
include_recipe "pivotal_ci::jenkins"