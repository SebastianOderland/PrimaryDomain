#!/usr/local/cpanel/3rdparty/bin/perl

BEGIN {
    unshift @INC, '/usr/local/cpanel';
}

use Cpanel::LiveAPI ();
use Cpanel::AdminBin::Call;

my $cpanel = Cpanel::LiveAPI->new();
my $cpanel = new CPANEL();

$| = 1;


my $USERPATH = $cpanel->cpanelprint('$homedir');
$function_result = $cpanel->uapi(
    'Variables', 'get_user_information',
    array(
        'parameter'     => 'value',
        'parameter'     => 'value',
        'parameter'     => 'value',
         )
);
SET current_primary_domain = execute("Variables", "get_user_information",
    {
        'name' => 'domain',
    });
my $CURRENT_PRIMARY_DOMAIN = $function_result.data.domain;
print "Content-type: text/html\r\n\r\n";
print $cpanel->header('Update Primary Domain');
print <<END;
<!DOCTYPE html>
<html>
<head>
<title>
Simple Website Infection Scanner</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
<div class="body-content">

    [% IF CPANEL.feature("update_primary_domain") %]
        <p id="descAddon" class="description">
            [% locale.maketext("Read more about this [output,url,_1,here,target,_2,id,_3].", "https://www.oderland.se/support/artikel/hur-byter-jag-huvuddoman-pa-mitt-webbhotellkonto/", "_blank", "lnkPimaryDomainDocumentation") %]
        </p>

            [% roots %]
            <div class="section">
                <h2>[% locale.maketext("Update Primary Domain Name") %]</h2>
                <form id="mainform" method="post" action="doupdateprimarydomain.html" name="mainform">
                    <!-- prevent password autofill -->
                    <input type="text" style="display:none">
                    <input type="password" autocomplete='off' style="display:none">
                    <div class="form-group">
                        <label id="lblDomain" for="domain">
                            [% locale.maketext("New Primary Domain Name") %]
                        </label>
                        <div class="row">
                            <div class="col-xs-12 col-sm-6 col-md-6 col-lg-6">
                                <input value="[% current_primary_domain.data.domain %]" id="domain" type="text" class="form-control hide-clear-button" name="domain" />
                                <div id="domain_info" class="hide">
                                    <div class="alert alert-info no-bottom-margin extra-top-margin" role="alert">
                                        <span class="glyphicon glyphicon-info-sign" aria-hidden="true"></span>
                                        <div class="alert-message">[% locale.maketext('This addon domain looks like a subdomain of your current domain or another domain you own. Would you like to [output,url,_1,create a subdomain instead]?', '../subdomain/index.html') %]</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-xs-12 col-sm-6 col-md-6 col-lg-6">
                                <div id="domain_error" class="show_inline"></div>
                            </div>
                        </div>
                    </div>

                    <div class="form-group">
                        <input id="submit_domain" name="go" type="submit" class="btn btn-primary" name="button-create" value="[% locale.maketext("Update") %]" />
                    </div>
                </form>
            </div>
    [% END %]

</div>
END

 
# $result will be “hello”:
my $result = Cpanel::AdminBin::Call::call('UpdatePrimaryDomain', 'UpdatePrimaryDomain', 'SAY_HI');
print "ECHO test:\n" . $results . "\n\n";
 

# @results will contain the 3 values that GET_INFO() returns.
# $results[0] will be ['foo', 'bar'].
my @results = Cpanel::AdminBin::Call::call('UpdatePrimaryDomain', 'UpdatePrimaryDomain', 'GET_INFO', 'foo', 'bar');
print "ECHO test:\n" . @results . "\n\n";

print <<END;
<a href="../index.html">Home</a>
END

print $cpanel->footer();
$cpanel->end();