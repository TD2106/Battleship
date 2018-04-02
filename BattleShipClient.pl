use IO::Socket;
@ships=();
%hash = ('a'=>1 ,'b'=>2,'c'=>3,'d'=>4,'e'=>5);
$socket = new IO::Socket::INET (
                                  PeerAddr  => '127.0.0.1',
                                  PeerPort  =>  9999,
                                  Proto => 'tcp',
                               )                
or die "Couldn't connect to Server\n";
sub stringToArray2d{
	$string = $_[0];
	@nums = ();
	@nums = split (" ",$string);
	@a = ();
	@result = ([0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]);
	for($i = 0;$i<5;$i++){
		for($j = 0;$j<5;$j++){
			$result[$i][$j] = $nums[$i*5+$j];
		}
	}
	return @result;
}
sub stringToArray1d{
	$string = $_[0];
	@hp = split (" ",$string);
}
sub isValid{
	$x = $_[0];
	$y = $_[1];
	if($x<1||$x>5||$y<1||$y>5){
		return 0;
	}
	else{
		return 1;
	}
}
sub isAdjacent{
	$x1 = $_[0];
	$y1 = $_[1];
	$x2 = $_[2];
	$y2 = $_[3];
	if( ($x1-$x2 == 1 and $y1 == $y2 ) or ($y1-$y2 == 1 and $x1 == $x2)
		or ($x1-$x2 == -1 and $y1 == $y2 ) or ($y1-$y2 == -1 and $x1 == $x2) ){
		return 1;
	}
	else{
		return 0;
	}
}
sub move{
	$xold=0;
	$yold=0;
	while(1){
		print "Input row of ship need to move\n";
		$xold=<>; 
		chop($xold);
		print "Input column of ship need to move\n";
		$yold=<>;
		chop($yold);
		if(!exists($hash{$yold})){
			print "Input again wrong coordinate\n";
			next;
		}
		else{
			$yold = $hash{$yold};
		}
		if(isValid($xold,$yold) != 1 ){
			print "Input again wrong coordinate\n";
		} 
		elsif($ships[$xold-1][$yold-1] == 0){
			print "Input again wrong coordinate\n";
		}
		else{
			last;
		}
	}
	$xnew=0;
	$ynew=0;
	print "You need to input the new empty coordinate so that the new coordinate is adjacent to the old one\n";
	while(1){
		print "Input row of new position\n";
		$xnew=<>; 
		chop($xnew);
		print "Input column of new position\n";
		$ynew=<>;
		chop($ynew);
		print $ynew;
		print "\n";
		if(!exists($hash{$ynew})){
			print "Input again wrong coordinate\n";
			next;
		}
		else{
			$ynew = $hash{$ynew};
		}
		if(isValid($xnew,$ynew) != 1 ){
			print "Input again wrong coordinate\n";
		} 
		elsif($ships[$xnew-1][$ynew-1] != 0){
			print "Not empty coordinate\n";
		}
		elsif(isAdjacent($xold,$yold,$xnew,$ynew) != 1){
			print "Input again not adjacent coordinate\n";
		}
		else{
			last;
		}
	}
	$socket->send($xold);
	sleep(0.5);
	$socket->send($yold);
	sleep(0.5);
	$socket->send($xnew);
	sleep(0.5);
	$socket->send($ynew);
	sleep(0.5);
}
sub wantToMove{
	while(1){
		print "Input y for yes n for no (moving ship)\n";
		$command = <>;
		chop($command);
		if($command eq 'y'){
			return 1;
			last;
		}
		elsif($command eq 'n'){
			return 0;
			last;
		}
		else{
			print "Wrong command\n";
		}
	}
}
sub shoot{
	$x = 0;
	$y = 0;
	while(1){
		print "Input row of shoot coordinate\n";
		$x=<>; 
		chop($x);
		print "Input column of shoot coordinate\n";
		$y=<>;
		chop($y);
		if(!exists($hash{$y})){
			print "Input again wrong coordinate\n";
			next;
		}
		else{
			$y = $hash{$y};
		}
		if(isValid($x,$y) != 1 ){
			print "Input again wrong coordinate\n";
		} 
		elsif($ships[$x-1][$y-1] != 0){
			print "You can't fire your own ship\n";
		}
		else{

			last;
		}
	}
	$socket->send($x);
	sleep(0.5);
	$socket->send($y);
}
sub visualization{
	$header = "  a b c d e\n";
	print $header;
	for($i = 0;$i<5;$i++){
		print $i+1;
		print " ";
		for($j = 0;$j<5;$j++){
			print "$ships[$i][$j] ";
		}
		print "\n";
	}
}
sub printHP{
	print "Current hp of ships\n";
	$string = $_[0];
	@hp = stringToArray2d($string);
	$header = "  a b c d e\n";
	print $header;
	for($i = 0;$i<5;$i++){
		print $i+1;
		print " ";
		for($j = 0;$j<5;$j++){
			print "$hp[$i][$j] ";
		}
		print "\n";
	}
}
$socket->recv($received_data,1024);
print $received_data;
$socket->recv($playerID,1024);
while(1){
	$socket->recv($received_data,1024);
	@ships = stringToArray2d($received_data);
	visualization();
	$socket->recv($received_data,1024);
	printHP($received_data);
	if($playerID == 2){
		print "After player 1 turn\n";
		$socket->recv($received_data,1024);
		printHP($received_data);
		$socket->recv($received_data,1024);
		if($received_data eq "Game is still going\n"){
			print $received_data;
		}
		else{
			print $received_data;
			close $socket;
			last;
		}
	}
	$socket->recv($received_data,1024);
	if($received_data eq "Your turn\n"){
		print $received_data;
		if(wantToMove()==1){
			$socket->send(1);
			move();
			$socket->recv($received_data,1024);
			print $received_data;
			$socket->recv($received_data,1024);
			@ships = stringToArray2d($received_data);
			visualization();
			$socket->recv($received_data,1024);
			printHP($received_data);
		}
		else{
			$socket->send(0);
		}
		shoot();
		$socket->recv($received_data,1024);
		print $received_data;
		$socket->recv($received_data,1024);
		print $received_data;
		if($received_data eq "Game is still going\n"){
			print 1;
		}
		else{
			close $socket;
			last;
		}
	}
	if($playerID == 1){
		print "After player 2 turn\n";
		$socket->recv($received_data,1024);
		printHP($received_data);
		$socket->recv($received_data,1024);
		if($received_data eq "Game is still going\n"){
			print $received_data;
		}
		else{
			print $received_data;
			close $socket;
			last;
		}
	}
}