<?php
  $dbname="gauntlet" ;
  $dbhost="localhost" ;
  $dbpass="Bmyfr1end" ;
  $dbuser="root" ;
  $debug = 1001;
$dbcon=mysql_connect ($dbhost, $dbuser, $dbpass) or exit ("<p><font color=red>Couldn't connect to database</font></p>");

  $db_selected = mysql_select_db($dbname) ;
  if ( ! $db_selected ) {
    die ('Can\'t use DB : ' . mysql_error());
  }


?>
