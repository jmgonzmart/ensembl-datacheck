=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::CheckMultipleAlignCoverage;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckMultipleAlignCoverage',
  DESCRIPTION => 'Coverage for a multiple whole genome alignment MLSS matches the coverage recorded in the  mlss_tag table',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'species_tree_node', 'species_tree_node_tag']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @methods = qw( EPO EPO_EXTENDED PECAN );
    my $db_name = $self->dba->dbc->dbname;

    my @mlsses;
    foreach my $method ( @methods ) {
      my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
      push @mlsses, @$mlss;
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no multiple alignments in $db_name" );
    }

}

sub tests {
  my ($self) = @_;
    
  my $helper  = $self->dba->dbc->sql_helper;
  
  my $msa_mlss_sql = qq/
    SELECT method_link_species_set_id 
      FROM method_link_species_set 
        JOIN method_link USING(method_link_id) 
      WHERE method_link.type IN ('EPO', 'EPO_EXTENDED', 'PECAN')
    /;
  
  my $msa_mlss_array = $helper->execute_simple(-SQL => $msa_mlss_sql);
  foreach my $mlss_id (@$msa_mlss_array) {
    
    my $genomic_align_coverage_sql = qq/
    SELECT d.genome_db_id, SUM(ga.dnafrag_end-ga.dnafrag_start+1) AS genomic_align_coverage 
      FROM genomic_align ga 
        JOIN dnafrag d USING(dnafrag_id) 
      WHERE ga.method_link_species_set_id = $mlss_id 
      GROUP BY d.genome_db_id
    /;

    my $tag_coverage_sql = qq/
    SELECT n.genome_db_id, n.node_name, t.value AS tag_coverage, g.genomic_align_coverage
      FROM species_tree_node n 
        JOIN species_tree_root r USING(root_id)
        JOIN species_tree_node_tag t USING(node_id) 
        JOIN ( $genomic_align_coverage_sql )g USING(genome_db_id) 
      WHERE n.genome_db_id IS NOT NULL 
        AND t.tag = 'genome_coverage' 
        AND r.method_link_species_set_id = $mlss_id
        AND g.genomic_align_coverage < t.value
    /;

    my $desc_2 = "genomic_align coverage matches species_tree_node_tag for mlss_id: $mlss_id";

    is_rows_zero($self->dba, $tag_coverage_sql, $desc_2);
    
  }
}

1;

