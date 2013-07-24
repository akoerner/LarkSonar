use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# # the contents of the Makefile that is written.
WriteMakefile(
     		'NAME'	=> 'LarkSonar',
         	'VERSION'     => "3.1",
         	'ABSTRACT'    => "perfSONAR client library abstraction layer for the NSF lark project",
			'PREREQ_PM' => {
										"perfSONAR_PS" => 0,
										"XML::LibXML" => 0,
										"XML::Twig" => 0,
										"XML::DOM" => 0,
										"Exporter" => 0,
										"XML::LibXML" => 0,
										"Data::Dumper" => 0,
									}
);
