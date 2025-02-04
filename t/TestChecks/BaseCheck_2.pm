=head1 LICENSE

# Copyright [2018-2021] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=cut

package TestChecks::BaseCheck_2;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::BaseCheck';

use constant {
  NAME           => 'BaseCheck_2',
  DESCRIPTION    => 'Failing BaseCheck example.',
  GROUPS         => ['base'],
  DATACHECK_TYPE => 'advisory',
};

sub tests {
  fail();
}

1;
