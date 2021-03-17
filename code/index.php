<?php

function update_primary_domain($user, $new_primary_domain)
{
    $command = "/usr/local/cpanel/bin/whmapi1 modifyacct user=".$user." DNS=".$new_primary_domain;
    echo shell_exec($command);
}

#$cpanel = new CPANEL(); // Connect to cPanel - only do this once.



echo readfile("template.html");

?>