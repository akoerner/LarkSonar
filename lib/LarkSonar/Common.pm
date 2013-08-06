package LarkSonar::Common;

our $VERSION = 1.0;

# copyright 2013 UNL Holland Computing Center
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#  
#        http://www.apache.org/licenses/LICENSE-2.0
#  
#    Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#This module utilizes features from the OnTimeDetect tool http://ontimedetect.oar.net/
#The following citation is for the OnTimeDetect tool:

=begin OnTimeDetect citation 
P. Calyam, J. Pu, W. Mandrawa, A. Krishnamurthy, "OnTimeDetect: Dynamic Network Anomaly Notification in perfSONAR Deployments", IEEE Symposium on Modeling, Analysis & Simulation of 
Computer & Telecommn. Systems (MASCOTS), 2010.
=end OnTimeDetect citation
=cut

#The following is a license for the OnTimeDetectTool

=begin OnTimeDetect License 
COPYRIGHT  © 2010 OARnet/OSC, THE OHIO STATE UNIVERSITY
ALL RIGHTS RESERVED

OnTimeDetect v0.1-DOE-sponsored perfSONAR Anomaly Detection Analysis Tool


AUTHORS:

PRASAD CALYAM, JIALU PU, LAKSHMI KUMARASAMY

PERMISSION IS HEREBY GRANTED, FREE OF CHARGE, TO USE, COPY, CREATE
DERIVATIVE WORKS AND REDISTRIBUTE THIS ACTIVEMON SOFTWARE AND
ASSOCIATED DOCUMENTATION(THE "SOFTWARE") AND SUCH DERIVATIVE
WORKS IN SOURCE AND OBJECT CODE FORM WITHOUT RESTRICTION, 
AND PROVIDED THAT THE ABOVE COPYRIGHT NOTICE, THIS GRANT
OF PERMISSION, AND THE DISCLAIMER BELOW APPEAR IN ALL COPIES
AND DERIVATIVES MADE;AND PROVIDED THAT THE OHIO STATE UNIVERSITY
AND AUTHORS OF THE SOFTWARE ARE ACKNOWLEDGED IN ANY PUBLICATIONS
REPORTING ITS USE,AND THE NAME OF THE OHIO STATE UNIVERSITY
OR ANY OF ITS OFFICERS,EMPLOYEES, STUDENTS OR BOARD MEMBERS
IS NOT USED IN ANY ADVERTISING OR PUBLICITY PERTAINING TO THE
USE OR DISTRIBUTION OF THE SOFTWARE WITHOUT SPECIFIC,
WRITTEN PRIOR AUTHORIZATION.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT REPRESENTATION FROM
THE OHIO STATE UNIVERSITY AS TO ITS FITNESS FOR ANY PURPOSE,
AND WITHOUT WARRANTY BY THE OHIO STATE UNIVERSITY OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
PARTICULAR PURPOSE. THE OHIO STATE UNIVERSITY HAS NO OBLIGATION
TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
OTHER MODIFICATIONS. THE OHIO STATE UNIVERSITY SHALL NOT BE 
LIABLE FOR COMPENSATORY OR NON-COMPENSATORY DAMAGES, INCLUDING
BUT NOT LIMITED TO SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WITH RESPECT TO ANY CLAIM ARISING OUT OF OR IN CONNECTION
WITH THE USE OF THE SOFTWARE, EVEN IF IT HAS BEEN OR IS HEREAFTER
ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
=end OnTimeDetect License
=cut


use threads;
use perfSONAR_PS::Client::LS;
use perfSONAR_PS::Client::MA;
use XML::LibXML;
use XML::Twig;
use XML::DOM;
use perfSONAR_PS::Common qw( find findvalue );
use JSON;
use Data::Dumper;



=head1 NAME

LarkSonar::Common

=head1 DESCRIPTION

A module that provides common methods for performing simple, necessary actions
within the perfSONAR framework.

=cut




require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(et_gls_projects get_ls_sitelist list_all_endpoints_with_throughput_data_available);



sub initiate_gls{


	my $gLs;

	($gLs) = @_;
	#print $gLs; 
	#if($gLs==1 || $gLs == '')
	#{
	
	##	$gLs = 'http://ps1.es.net:9990/perfSONAR_PS/services/gLS';
	#}
	
	my $glsClient = new perfSONAR_PS::Client::LS
	(
		{
			instance => $gLs
		}
	)  or die "Invalid Global Lookup Service address";
	
	
	return $glsClient;
}

sub query_to_gls{

	($glsClient,$query_keyword) = @_;

	my $gLSResult = $glsClient->queryRequestLS(
		{
		    query => $query_keyword,
		    format => 1 #want response to be formated as XML
		}
	);

	return $gLSResult->{response};

}

sub get_gls_keyword{

	my $xls_global_query_lookup = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
	$xls_global_query_lookup .= "/nmwg:store[\@type=\"LSStore\"]/nmwg:data/nmwg:metadata/summary:parameters/nmwg:parameter[\@name=\"keyword\"]";
	return $xls_global_query_lookup;
}

sub get_gls_sitelist{
	my $sitename;

	($sitename) = @_;

	my $gLSXquery = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
	$gLSXquery .= "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
	$gLSXquery .= "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
	$gLSXquery .= "declare namespace summary=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/summarization/2.0/\";\n";
	$gLSXquery .= "for \$metadata in /nmwg:store[\@type=\"LSStore\"]/nmwg:metadata\n";
	$gLSXquery .= "    let \$metadata_id := \$metadata/\@id  \n";
	$gLSXquery .= "    let \$data := /nmwg:store[\@type=\"LSStore\"]/nmwg:data[\@metadataIdRef=\$metadata_id]\n";
	$gLSXquery .= "    let \$keyword := \$data/nmwg:metadata/summary:parameters/nmwg:parameter[\@name=\"keyword\"]/\@value\n ";
	$gLSXquery .= "    let \$eventTypeParam := \$data/nmwg:metadata/summary:parameters/nmwg:parameter[\@name=\"eventType\"]/\@value\n ";
	$gLSXquery .= "    where (\$metadata/perfsonar:subject/psservice:service/psservice:serviceType=\"ls\" or ";
	$gLSXquery .= "       \$metadata/perfsonar:subject/psservice:service/psservice:serviceType=\"hLS\") and ";
	$gLSXquery .= "        (\$eventTypeParam=\"http://ggf.org/ns/nmwg/tools/bwctl/1.0\")";
	$gLSXquery .= "        and (\$keyword=\"$sitename\")";
	$gLSXquery .= "    return \$metadata/perfsonar:subject/psservice:service/psservice:accessPoint";
	return $gLSXquery;

}

sub get_hls_sitelist{
	my $sitename;

	($sitename) = @_;
	my $hLSXquery = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
	$hLSXquery .= "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
	$hLSXquery .= "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
	$hLSXquery .= "declare namespace nmtb=\"http://ogf.org/schema/network/base/20070828/\";\n";
	$hLSXquery .= "for \$metadata in /nmwg:store[\@type=\"LSStore\"]/nmwg:metadata\n";
	$hLSXquery .= "    let \$metadata_id := \$metadata/\@id  \n";
	$hLSXquery .= "    let \$data := /nmwg:store[\@type=\"LSStore\"]/nmwg:data[\@metadataIdRef=\$metadata_id]\n";
	$hLSXquery .= "    let \$keyword := \$data/nmwg:metadata/nmwg:parameters/nmwg:parameter[\@name=\"keyword\"]";
	$hLSXquery .= "    where \$metadata/perfsonar:subject/nmtb:service/nmtb:type=\"bwctl\" and (\$keyword=\"$sitename\")";

	$hLSXquery .= "    return \$metadata/perfsonar:subject/nmtb:service/nmtb:address";
	return $hLSXquery;

}

sub get_xls_pairlist{
	my $subject = "<iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0\" id=\"subject\">\n";
	$subject .=   "    <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
	$subject .=   "</iperf:subject>\n";

	return $subject;

}

sub get_ls_sitelist{
	my $project_name;
	my $gLs;

	($project_name, $gLs) = @_;

	#print $gLs
	
	my @sites = ();
	
	my $xls_gls_sitelist = get_gls_sitelist("project:".$project_name);
	my $xls_hls_sitelist = get_hls_sitelist("project:".$project_name); 
	
	my $gLSClient = initiate_gls($gLs);

	my $gLSResult = query_to_gls($gLSClient,$xls_gls_sitelist);
	
	if ($gLSResult eq "")
	{
		return -1;
	} 

	my $parser = XML::LibXML->new();
	
	my $gLSDoc = $parser->parse_string($gLSResult);
	my $hLSList = find($gLSDoc->getDocumentElement, "./*[local-name()='accessPoint']", 0);

	for(my $i = 0; $i < $hLSList->size(); $i++)
	{ 
		my $hLSUrl =  $hLSList->get_node($i)->string_value();

		my $hlsClient = new perfSONAR_PS::Client::LS(
		{
		instance => $hLSUrl
		}
		);
		my $hLSResult = $hlsClient->queryRequestLS(
		{
		query => $xls_hls_sitelist,
		format => 1
		}
		);

		my $resParser = XML::LibXML->new();
		
		if($hLSResult->{response} && $hLSResult->{response} =~ /^</)
		{

			my $hLSDoc = $resParser->parse_string($hLSResult->{response});
			my $bwctlList = find($hLSDoc->getDocumentElement, "./*[local-name()='address']", 0);
			for(my $j = 0; $j < $bwctlList->size(); $j++)
			{
				my $output = $bwctlList->get_node($j)->string_value();
				my $find = "tcp://";
				my $replace = "";
				$find = quotemeta $find;
				$output =~ s/$find/$replace/g;
				$find = ":4823";
				$output =~ s/$find/$replace/g;
				
				$find = "http://";
				$output =~ s/$find/$replace/g;
				


				#print $output."\n";
				push( @sites, $output);
				#push(@sitelist_list,$bwctlList->get_node($j)->string_value()); 
			}
		}
	}
	

	my $hash = {"site"=>\@sites};
	
	my $json = JSON->new->allow_nonref;
	my $encoded = $json->encode($hash);
	
	return $encoded;

	

}

sub get_gls_projects{
	($gLs) = @_;
	
	my $array_size = 0;
	my $xls_keyword = get_gls_keyword();
	my $gLSClient = initiate_gls($gLs);
	
	my $gLSResult = query_to_gls($gLSClient,$xls_keyword);
	
	if ($gLSResult eq ""){
		return;
	}
	my @projects = parse_query_keyword($gLSResult);

	for my $project(@projects){
		my $find = "project:";
		my $replace = "";
		$project =~ s/$find/$replace/g;
	}
	
	my $hash = {"project"=>\@projects};
	
	my $json = JSON->new->allow_nonref;
	my $encoded = $json->encode($hash);

	return $encoded;
	#print scalar(@projects);
}

sub parse_query_keyword{
	my $result;
	($result) = @_;
	
	my $xml_parser = XML::DOM::Parser->new();

	my $doc = $xml_parser->parse($result) or die "Unable to parse document";
	my $flag = 0;
	my @prj_array;
	my $text1;
	my $text2;

	foreach my $node($doc->getElementsByTagName("nmwg:parameter"))
	{ 
		$flag = 0;
		$text1 = $node->getAttribute("value");
		$text2 = chomp($text1);
		my $size_array = @project_list;
		if ($size_array > 0)
		{
			foreach my $element(@project_list)
			{
				if ($element eq $text1)
				{
					$flag = 1;	
				}
			}
		}

		if ($flag eq 0)
		{
			@prj_array = split(":",$text1);
			if ($prj_array[0] eq "project")
			{
				push(@project_list,$node->getAttribute("value"));
			}
		}


	}

	return @project_list;

}

sub list_all_router_interfaces_with_collected_SNMP_data{
	($site) = @_;
	
	my $resource = ":8080/perfSONAR_PS/services/snmpMA";
	
	# Create client
	my $ma = new perfSONAR_PS::Client::MA( { instance => "http://".$site.$resource } );

	# Specify subject
	my $subject = "<netutil:subject xmlns:netutil=\"http://ggf.org/ns/nmwg/characteristic/utilization/2.0\" id=\"s\">\n";
	$subject .= "    <nmwgt:interface xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
	$subject .= "</netutil:subject>\n";

	# Specify eventType
	my @eventTypes = ('http://ggf.org/ns/nmwg/characteristic/utilization/2.0');

	# Send request
	my $result = $ma->metadataKeyRequest(
			{
				subject    => $subject,
				eventTypes => \@eventTypes,
			}
		);

	#Output XML
	my $parser = XML::LibXML->new();
	foreach $metadata(@{$result->{"metadata"}}){
		my $doc = $parser->parse_string($metadata);
		my $xpath = "./*[local-name()='subject']/*[local-name()='interface']";
		#print find($doc->getDocumentElement, "$xpath/*[local-name()='ifName']", 0) . ' ';
		print find($doc->getDocumentElement, "$xpath/*[local-name()='ifAddress']", 0) . ' ';
		#print find($doc->getDocumentElement, "$xpath/*[local-name()='hostName']", 0) . ' ';
		#print find($doc->getDocumentElement, "$xpath/*[local-name()='direction']", 0) . ' ';
		#print find($doc->getDocumentElement, "$xpath/*[local-name()='capacity']", 0);
		#Sprint find($doc->getDocumentElement, "$xpath/*[local-name()='description']", 0) . "\n";	
	}
}

sub return_n_minute_utilization_on_a_specific_interface(){
	
	($site, $interfaceAddress, $nMinuteResolution, $secondsAgo, $functionNumber) = @_;
	
	my $resource = ":8080/perfSONAR_PS/services/snmpMA";
	
	my @function  = ("AVERAGE", "MAIMUM");
	
	# Create client
	my $ma = new perfSONAR_PS::Client::MA( { instance => "http://".$site.$resource } );
	
	# Set subject
	my $subject = "<netutil:subject xmlns:netutil=\"http://ggf.org/ns/nmwg/characteristic/utilization/2.0\" id=\"s\">\n";
	$subject .= "    <nmwgt:interface xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";
	$subject .= "       <nmwgt:ifAddress type=\"ipv4\">".$interfaceAddress."</nmwgt:ifAddress>";
	$subject .= "    </nmwgt:interface>";
	$subject .= "</netutil:subject>\n";

	#Set event type
	my @eventTypes = ();

	# Set time range
	my $end = time;
	my $start = $end - $secondsAgo;

	# Send request        
	my $result = $ma->setupDataRequest(
			{
				subject    => $subject,
				eventTypes => \@eventTypes,
				start => $start,
				end  => $end,
				consolidationFunction => $function[$functionNumber],
				resolution => $nMinuteResolution
			}
		);

	#Output XML
	my $twig= XML::Twig->new(pretty_print => 'indented');
	foreach $metadata(@{$result->{"metadata"}}){
		$twig->parse($metadata);
		$twig->print();
	}
	foreach $data(@{$result->{"data"}}){
		$twig->parse($data);
		$twig->print();
	}


}

sub list_all_endpoints_with_throughput_data_available{

	($site) = @_;

	my @endpoints;

	my @source = ();
	my @destination = ();
	my $count = 0;

	my $xls_pairlist = get_xls_pairlist();

	my $data_sitename = $site;

	my $data_http_name = "http://" . $site . ":8085/perfSONAR_PS/services/pSB ";

	# Set eventType
	my @eventTypes = ('http://ggf.org/ns/nmwg/tools/iperf/2.0');

	my $is_data_empty = 0;

	my $ma = new perfSONAR_PS::Client::MA( { instance => "$data_http_name" } );

	# Send request
	my $result = $ma->setupDataRequest(
	{
	subject    => $xls_pairlist,
	eventTypes => \@eventTypes,
	}
	); 
	
	my $parser = XML::LibXML->new();
	my $twig= XML::Twig->new(pretty_print => 'indented');
	my $resultString = "";
	
	foreach $metadata(@{$result->{"metadata"}}){
		$twig->parse($metadata);
		$resultString .= $twig->sprint;
	}
	
	$resultString = "<data>\n".$resultString."\n</data>";
	
	my $parser = XML::LibXML->new();
	
	my $doc = $parser->parse_string($resultString);

	foreach my $node($doc->getElementsByTagName("nmwg:metadata")){
		foreach my $tnode($node->getElementsByTagName("nmwgt:src")){
			$source[$count] = $tnode->getAttribute("value");
		}

		foreach my $tnode($node->getElementsByTagName("nmwgt:dst")){
			$destination[$count] = $tnode->getAttribute("value");
		}
		my $tempPair = {"source"=>$source[$count], "destination"=>$destination[$count++]};
		push(@endpoints, $tempPair);
		

	}
	
	my $hash = {"endpoint_pair"=>\@endpoints};
	
	my $json = JSON->new->allow_nonref;
	my $encoded = $json->encode($hash);
	
	return $encoded;
	#print @endpoints;
}

sub list_all_endpoints_with_one_way_latency_data_available{

	($site) = @_;
	
	my $resource = ":8085/perfSONAR_PS/services/pSB";
	my @endpoints;
	
	my @source = ();
	my @destination = ();
	
	# Create client
	my $ma = new perfSONAR_PS::Client::MA( { instance => "http://".$site.$resource } );

	# Define the subject
	my $subject = "<owamp:subject xmlns:owamp=\"http://ggf.org/ns/nmwg/tools/owamp/2.0/\" id=\"subject\">\n";
	$subject .=   "    <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
	$subject .=   "</owamp:subject>\n";

	# Set the eventType
	my @eventTypes = ('http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921');

	# Send request
	my $result = $ma->metadataKeyRequest(
			{
				subject    => $subject,
				eventTypes => \@eventTypes
			}
		);

	my $parser = XML::LibXML->new();
	my $twig= XML::Twig->new(pretty_print => 'indented');
	$resultString = "";
	foreach $metadata(@{$result->{"metadata"}}){
		$twig->parse($metadata);
		
		$resultString .= $twig->sprint;
	}
	
	$resultString = "<data>\n".$resultString."\n</data>";

	#print $resultString;
	
	my $parser = XML::LibXML->new();
	
	my $doc = $parser->parse_string($resultString);



	foreach my $node($doc->getElementsByTagName("nmwg:metadata"))
	{


		push(@metadata_files,$node->getAttribute("id"));


		foreach my $tnode($node->getElementsByTagName("nmwgt:src")){

			$source[$count] = $tnode->getAttribute("value");
		}

		foreach my $tnode($node->getElementsByTagName("nmwgt:dst")){
			$destination[$count] = $tnode->getAttribute("value");
		}
	
		my $tempPair = {"source"=>$source[$count], "destination"=>$destination[$count++]};
		push(@endpoints, $tempPair);
		

	}
	
	my $hash = {"endpoint_pair"=>\@endpoints};
	
	my $json = JSON->new->allow_nonref;
	my $encoded = $json->encode($hash);
	
	print $encoded;
}

sub get_throughput_between_two_endpoints{

	($site, $source, $destination, $startUnixTimestamp, $endUnixTimestamp) = @_;
	
	my $resource = ":8085/perfSONAR_PS/services/pSB";
	my @results;

	# Create client
	my $ma = new perfSONAR_PS::Client::MA( { instance => "http://".$site.$resource } );

	# Define subject
	my $subject = "<iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0\" id=\"subject\">\n";
	$subject .=   "    <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">";
	$subject .=   "        <nmwgt:src type=\"hostname\" value=\"".$source."\"/>";
	$subject .=   "        <nmwgt:dst type=\"hostname\" value=\"".$destination."\"/>";
	$subject .=   "    </nmwgt:endPointPair>";
	$subject .=   "</iperf:subject>\n";

	# Set eventType
	my @eventTypes = ();
	
	# Send request
	my $result = $ma->setupDataRequest(
			{
				subject    => $subject,
				eventTypes => \@eventTypes,
				start      => $startUnixTimestamp,
				end        => $endUnixTimestamp
			}
		);

	#Output XML
	my $parser = XML::LibXML->new();

	my $twig= XML::Twig->new(pretty_print => 'indented');
	foreach $metadata(@{$result->{"metadata"}}){
		$twig->parse($metadata);
		#SS$twig->print();
	}
	
	#print Dumper($result->{"data"});
	
	foreach $data(@{$result->{"data"}}){
		#print $data;
		my $doc = $parser->parse_string($data);
		
		foreach my $node($doc->getElementsByTagName("iperf:datum")){
			my $tempThroughput = {"throughput"=>$node->getAttribute("throughput"), "timestamp"=>$node->getAttribute("timeValue")};
			push(@results, $tempThroughput);
		}
		
	}
	
	my $hash = {"throughput_result"=>\@results};
	
	my $json = JSON->new->allow_nonref;
	my $encoded = $json->encode($hash);
	
	print $encoded;
}

sub get_one_way_latency_between_two_endpoints{

	($site, $source, $destination, $startUnixTimestamp, $endUnixTimestamp) = @_;

	#source and destination are 
	#Supports IPv4 and IPv6
	
	my $resource = ":8085/perfSONAR_PS/services/pSB";
	my @results;
	
	# Create client
	my $ma = new perfSONAR_PS::Client::MA( { instance => "http://".$site.$resource } );
	
	my $sourceType = "type=";
	my $destinationType = "type=";
	
	if(index($source, ':') != -1){
		$sourceType .="\"ipv6\""
	}else{
		$sourceType .="\"ipv4\"";
	}
	
	if(index($destination, ':') != -1){
		$destinationType .="\"ipv6\""
	}else{
		$destinationType .="\"ipv4\"";
	}
	
	my $sourceSubject = " ".$sourceType." value=\"".$source."\"";
	my $destinationSubject = " ".$destinationType." value=\"".$destination."\"";
	
	# Define subject
	my $subject = "<owamp:subject xmlns:owamp=\"http://ggf.org/ns/nmwg/tools/owamp/2.0/\" id=\"subject\">\n";
	$subject .=   "    <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">";
	$subject .=   "        <nmwgt:src".$sourceSubject."/>";
	$subject .=   "        <nmwgt:dst".$destinationSubject."/>";
	$subject .=   "    </nmwgt:endPointPair>";
	$subject .=   "</owamp:subject>\n";
	
	#print $subject;

	my @eventTypes = ();

	# Send the request
	#print $subject;
	my $result = $ma->setupDataRequest(
			{
				subject    => $subject,
				eventTypes => \@eventTypes,

			}
		);

	#Output XML
	my $parser = XML::LibXML->new();
	
	#print Dumper($result);
	
	#Output XML


	my $twig= XML::Twig->new(pretty_print => 'indented');
	foreach $metadata(@{$result->{"metadata"}}){
		$twig->parse($metadata);
		$twig->print();
	}
	foreach $data(@{$result->{"data"}}){
		print $data;
		my $doc = $parser->parse_string($data);
		
		foreach my $node($doc->getElementsByTagName("summary:datum")){
			#print $node->getAttribute("duplicates");
			#print ",";
			#print $node->getAttribute("endTime");
			#print ",";
			#print $node->getAttribute("loss");
			#print ",";
			#print $node->getAttribute("maxError");
			#print ",";
			#print $node->getAttribute("maxTTL");
			#print ",";
			#print $node->getAttribute("max_delay");
			#print ",";
			#print $node->getAttribute("minTTL");
			#print ",";
			#print $node->getAttribute("min_delay");
			#print ",";
			#print $node->getAttribute("sent");
			#print ",";
			#print $node->getAttribute("startTime");
			#print ",";
			#print $node->getAttribute("timeType");
			#print ",";
			
			my $index = 0;
			my $nodeList = $node->getElementsByTagName("summary:value_bucket");
			
			
			foreach my $valueBucket($node->getElementsByTagName("summary:value_bucket")){
				#print ($node->getElementsByTagName("summary:value_bucket"))->[-1];
				if($index > 0){
					#print ";";
				}
				#print $valueBucket->getAttribute("count");
				#print  " ".$valueBucket->getAttribute("value");
				
				$index++;
			}
			#print "\n";
		}
		
	}
}

1;