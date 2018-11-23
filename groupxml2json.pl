#! /usr/bin/perl -w
#

use Data::Dumper;
use XML::LibXML;
use XML::LibXML::XPathContext;
use JSON;

my $filepath = "State2018MediaFileGroupsAndTickets.xml";

my $parser = XML::LibXML->new();
my $doc    = $parser->parse_file($filepath);

my $output = {'name'=>'Election', 'children' => []};

my $xpc = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs(eml => 'urn:oasis:names:tc:evs:schema:eml');
$xpc->registerNs(ns => 'http://www.aec.gov.au/xml/schema/mediafeed');

my @contests = $xpc->findnodes("//ns:SenateGroups/ns:Election/ns:Contests/ns:Contest");

foreach my $contest (@contests){
    my $con_name =  $xpc->findvalue('.//eml:ContestName', $contest);
    my $con = {'category'=>'Contest', 'name' => $con_name, 'children' => []};
    push($output->{'children'}, $con);

    foreach my $group ($xpc->findnodes('./ns:Group', $contest)){
        my $grp_name = $xpc->findvalue('.//ns:GroupName', $group);
        my $grp = {'category' => 'Group', 'name' => $grp_name, 'children' => []};
        push($con->{'children'}, $grp);
        my $ticketnum = 0;
               
          foreach my $ticket ($xpc->findnodes('./ns:GroupVotingTicket', $group)){
              my $tic_num = $ticket->getAttribute('TicketNumber');
              my $tic = {'category'=>'Ticket', 'children'=> [], 'name' => 'Ticket '.$tic_num};
              push($grp->{'children'}, $tic);

               foreach my $preference ($xpc->findnodes('./ns:Candidate', $ticket)){
                    $pref_name = $xpc->findvalue('.//eml:CandidateName', $preference);
                    $pref_party = $xpc->findvalue('.//eml:RegisteredName', $preference);
                    $pref_order = $xpc->findvalue('.//ns:Preference', $preference);

                    $pref = {'category' => 'Preference', 'name' => $pref_name.' ('.$pref_party.')',
                             'name_only' => $pref_name, 'party_only' => $pref_party,
                             'order' => $pref_order};
                   push($tic->{'children'}, $pref); 
               }
               $ticketnum++;
          }        
          # if we only have one ticket, we can remove this level
          if($ticketnum == 1){
              $grp->{'children'} = $grp->{'children'}[0]->{'children'};
          }

    }

}


$json = JSON->new->allow_nonref;
print $json->pretty->encode($output);

