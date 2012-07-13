<?php


include 'db.php' ;


header("Content-Type:", "text/csv") ;
# echo 'All OK<br>' ;
$sql='select hostname, domain, audit, status, result from tasks where jobid = 44 order by status desc into OUTFILE "/tmp/kk" FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY "\"" LINES TERMINATED BY "\r\n" ' ;

# $sql='select "Hostname", "Domain", "Audit", "Status", "Result" union "(select hostname, domain, audit, status, result from tasks where jobid = 44 order by status desc"' .  " INTO OUTFILE ' . $outfile . ' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n')";

# print "Sql = $sql<br>" ; 


$res = mysql_query($sql)  or die ( "Sql error : " . mysql_error( ) );


$nrows = mysql_num_rows($res);
for ($j=0; $j<$nrows; $j++ ) {
  $row = mysql_fetch_array($res) ;
  $line = '';
  foreach( $row as $value ) {
    if ( ( !isset( $value ) ) || ( $value == "" ) ) { 
      $value = "\t"; 
    }  else {
      $value = str_replace( '"' , '""' , $value );
      $value = '"' . $value . '"' . "\t";
    }
    $line .= $value;
  }
  $data .= trim( $line ) . "\n";
  if ( $data == "" )
  {
    $data = "\n(0) Records Found!\n"; 
  }
  print nl2br($data) ;

} 
if ( $nrows == 0 )  {
  echo  'No results Found' ;
}
print "Location: /tmp/kk" . param("job") . ".csv\n\n";
?>
