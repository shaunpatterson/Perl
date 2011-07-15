#!/usr/bin/perl

use Tree::Nary;

use strict;
use warnings;

sub printNode {
  my $node = shift;
  if (defined $node) {
    my $node_data = $node->{data};
    print $node_data . "\n";
  } 
  return 0;
}


my $baseTree = new Tree::Nary;

# Top level nodes
my $wordNode = Tree::Nary->new ('WORD: Test');
my $spaceNode = Tree::Nary->new ('WS: ');
my $wordNode2 = Tree::Nary->new ('WORD: one');

# Build word level nodes
my $varNode = Tree::Nary->new ('VAR: Test');
my $wsNode1 = Tree::Nary->new ('WS: T');
my $wsNode2 = Tree::Nary->new ('WS: e');
my $wsNode3 = Tree::Nary->new ('WS: s');
my $wsNode4 = Tree::Nary->new ('WS: t');
my $cNode1 = Tree::Nary->new ('C: T');
my $cNode2 = Tree::Nary->new ('C: e');
my $cNode3 = Tree::Nary->new ('C: s');
my $cNode4 = Tree::Nary->new ('C: T');

$varNode->append ($wordNode, $varNode);
$wsNode1->append ($varNode, $wsNode1);
$wsNode2->append ($varNode, $wsNode2);
$wsNode3->append ($varNode, $wsNode3);
$wsNode4->append ($varNode, $wsNode4);
$cNode1->append ($wsNode1, $cNode1);
$cNode2->append ($wsNode2, $cNode2);
$cNode3->append ($wsNode3, $cNode3);
$cNode4->append ($wsNode4, $cNode4);


# Build space word
#$spaceNode->append (Tree::Nary->new ('C: _'));

# Build last word
my $varNode2 = Tree::Nary->new ('VAR: one');
my $wsNode2_1 = Tree::Nary->new ('W: O');
my $wsNode2_2 = Tree::Nary->new ('W: n');
my $wsNode2_3 = Tree::Nary->new ('W: e');
my $cNode2_1 = Tree::Nary->new ('C: O');
my $cNode2_2 = Tree::Nary->new ('C: n');
my $cNode2_3 = Tree::Nary->new ('C: e');
my $stateNode = Tree::Nary->new ('STATE: NE');

#$wordNode2->append ($varNode2);
#$varNode2->append ($wsNode2_1);
#$varNode2->append ($stateNode);
#$wsNode2_1->append ($cNode2_1);
#$wsNode2_2->append ($cNode2_2);
#$wsNode2_3->append ($cNode2_3);
#$stateNode->append ($wsNode2_2);
#$stateNode->append ($wsNode2_3);

$wordNode->append ($baseTree, $wordNode);
#$spaceNode->append ($baseTree, $spaceNode);
#$wordNode2->append ($baseTree, $wordNode2);

#print Tree::Nary->n_nodes ($baseTree, $Tree::Nary::TRAVERSE_ALL) . "\n";
#print Tree::Nary->n_children ($baseTree) . "\n";

#print $wordNode->{data} . "\n";

#print Tree::Nary->first_child ($baseTree)->{data};

my $printsub = sub {
  my $node = shift;
  if (defined $node) {
    my $node_data = $node->{data};
    print $node_data . "\n";
  } 
  return 0;
};

#$baseTree->children_foreach ($baseTree, $Tree::Nary::TRAVERSE_ALL, \&printNode);

Tree::Nary->traverse ($baseTree, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&printNode);




