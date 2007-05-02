package DBIx::Class::Schema::Journal::DB;

use base 'DBIx::Class::Schema';

__PACKAGE__->mk_classdata('current_user');
__PACKAGE__->mk_classdata('current_session');
__PACKAGE__->mk_classdata('current_changeset');

DBIx::Class::Schema::Journal::DB->load_classes(qw/
                                               ChangeSet
                                               Change
                                               AuditLog
                                               AuditHistory
                                               /);

1;
