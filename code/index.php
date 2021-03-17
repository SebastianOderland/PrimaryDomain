<?php

function update_primary_domain($user, $new_primary_domain)
{
    $command = "/usr/local/cpanel/bin/whmapi1 modifyacct user=".$user." DNS=".$new_primary_domain;
    echo shell_exec($command);
}

$cpanel = new CPANEL(); // Connect to cPanel - only do this once.

$listaddondomains = $cpanel->api2(
    'Park', 'listaddondomains'
 
);

echo
<div class="body-content">

    [% IF CPANEL.feature("update_primary_domain") %]
        <p id="descAddon" class="description">
            [% locale.maketext("Read more about this [output,url,_1,here,target,_2,id,_3].", "https://www.oderland.se/support/artikel/hur-byter-jag-huvuddoman-pa-mitt-webbhotellkonto/", "_blank", "lnkPimaryDomainDocumentation") %]
        </p>


        [% resource_code %]
        [% IF !resource_usage_limits || !resource_usage_limits.is_maxed %]
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
                                <input id="domain" type="text" class="form-control hide-clear-button" name="domain" />
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
            </div><!-- end highlight -->
        [% END %]
    [% END %]<!-- end cpanelfeature addondomains -->

</div><!-- end body-content -->

?>