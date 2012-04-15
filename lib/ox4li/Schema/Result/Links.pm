package ox4li::Schema::Result::Links;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("links");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "code",
  {
    data_type => "string",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "url",
  {
    data_type => "string",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "count",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2012-04-13 22:07:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ShtBsQ8PvKKeISrdt7piuQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
