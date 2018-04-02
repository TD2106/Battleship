use IO::Socket;
%hash = ('a',0,'b',1,'c',2,'d',3,e,'4');
@ships=([0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]);
@indices=([0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]);
@hp=([100,100,100,100,100],[100,100,100,100,100]);
$socket = new IO::Socket::INET (
                                  LocalHost => '127.0.0.1',
                                  LocalPort => '9999',
                                  Proto => 'tcp',
                                  Listen => 10,
                                  Reuse => 1
                               );
                                
die "Coudn't open socket\n" unless $socket;

print "TCPServer Waiting for client on port 9999\n";

sub array2dToString{
	$result = "";
	$a = $_[0];
	for $item (@$a){
		$result.=join(" ",@$item);
		$result.=" ";
	}
	return $result;
}

sub shoot{
	$x = $_[0];
	$y = $_[1];
	if($ships[$x][$y] != 0){
		$hp[$ships[$x][$y]-1][$indices[$x][$y]-1] -= 50;
		if($hp[$ships[$x][$y]-1][$indices[$x][$y]-1] == 0){
			$ships[$x][$y] = 0;
			$indices[$x][$y] = 0;
		}
		return 1;
	}
	else{
		return 0;
	}
}
sub array1dToString{
	$result = "";
	$a = $_[0];
	$result = join(" ",@$a);
	return $result;
}

sub move{
	$xold = $_[0];
	$yold = $_[1];
	$xnew = $_[2];
	$ynew = $_[3];
	if($ships[$xnew][$ynew] == 0){
		$ships[$xnew][$ynew] = $ships[$xold][$yold];
		$indices[$xnew][$ynew] = $indices[$xold][$yold];
		$ships[$xold][$yold] = 0;
		$indices[$xold][$yold] = 0;
		return 1;
	}
	else{
		return 0;
	}
}
sub removeElementsFrom2dArray{
	$in = $_[0];
	@copyArr = ([0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]);
	$element = $_[1];
	for($i=0;$i<5;$i++){
		for($j=0;$j<5;$j++){
			$copyArr[$i][$j] = $$in[$i][$j];
			if($copyArr[$i][$j] == $element){
				$copyArr[$i][$j] = 0;
			}
		}
	}
	return @copyArr;
}

sub startGame{
	$cnt = 0;
	while($cnt<5){
		$x = int(rand(5));
		$y = int(rand(5));
		if($ships[$x][$y]==0){
			$cnt++;
			$ships[$x][$y] = 1;
			$indices[$x][$y] = $cnt;
		}
	}
	$cnt = 0;
	while($cnt<5){
		$x = int(rand(5));
		$y = int(rand(5));
		if($ships[$x][$y]==0){
			$cnt++;
			$ships[$x][$y] = 2;
			$indices[$x][$y] = $cnt;
		}
	}
	$hp[0][int(rand(5))]+=100;
	$hp[1][int(rand(5))]+=100;
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
sub checkLost{
	$id = $_[0];
	for($i=0;$i<5;$i++){
		if($hp[$id-1][i]>0){
			return 0;
		}
	}
	return 1;
}
sub sendHP{
	@sendHP = ([0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]);
	$id = $_[0];
	if($id == 1){
		$temp = 2;
	}
	else {
		$temp = 1;
	}
	@copy = removeElementsFrom2dArray(\@ships,$temp);
	for($i = 0;$i < 5;$i++){
		for($j = 0;$j < 5;$j++){
			if($copy[$i][$j]!=0){
				$sendHP[$i][$j] = $hp[($id-1)][($indices[$i][$j]-1)];
			}
		}
	}
	return array2dToString(\@sendHP);
}
startGame();
visualization();
$client_socket1 = $socket->accept();
print "Player 1 connect\n";
$client_socket1->send("You are player 1\n");
sleep(0.5);
$client_socket1->send(1);
$client_socket2 = $socket->accept();
print "Player 2 connect\n";
$client_socket2->send("You are player 2\n");
sleep(0.5);
$client_socket2->send(2);
while(1){
	@copy = removeElementsFrom2dArray(\@ships,2);
	$send_data = array2dToString(\@copy);
	$client_socket1->send($send_data);
	sleep(0.5);
	$client_socket1->send(sendHP(1));
	sleep(0.5);
	@copy = removeElementsFrom2dArray(\@ships,1);
	$send_data = array2dToString(\@copy);
	$client_socket2->send($send_data);
	sleep(0.5);
	$client_socket2->send(sendHP(2));
	sleep(0.5);
	$client_socket1->send("Your turn\n");
	$client_socket1->recv($mv,1024);
	if($mv == 1){
		$client_socket1->recv($xold,1024);
		$client_socket1->recv($yold,1024);
		$client_socket1->recv($xnew,1024);
		$client_socket1->recv($ynew,1024);
		if(move($xold-1,$yold-1,$xnew-1,$ynew-1) == 1){
			$client_socket1->send("Success move\n");
		}
		else{
			$client_socket1->send("Fail move\n");
		}
		@copy = removeElementsFrom2dArray(\@ships,2);
		$send_data = array2dToString(\@copy);
		$client_socket1->send($send_data);
		sleep(0.5);
		$client_socket1->send(sendHP(1));
		sleep(0.5);
	}
	$client_socket1->recv($x,1024);
	$client_socket1->recv($y,1024);
	if(shoot($x-1,$y-1)==1){
		$client_socket1->send("HIT\n");
	}
	else{
		$client_socket1->send("MISSED\n");
	}
	$client_socket2->send(sendHP(2));
	sleep(0.5);
	if(checkLost(2)==1){
		$client_socket1->send("You win\n");
		sleep(0.5);
		$client_socket2->send("You lose\n");
		sleep(0.5);
	}
	else{
		$client_socket1->send("Game is still going\n");
		sleep(0.5);
		$client_socket2->send("Game is still going\n");
		sleep(0.5);
	}
	$client_socket2->send("Your turn\n");
	$client_socket2->recv($mv,1024);
	if($mv == 1){
		$client_socket2->recv($xold,1024);
		$client_socket2->recv($yold,1024);
		$client_socket2->recv($xnew,1024);
		$client_socket2->recv($ynew,1024);
		if(move($xold-1,$yold-1,$xnew-1,$ynew-1) == 1){
			$client_socket2->send("Success move\n");
		}
		else{
			$client_socket2->send("Fail move\n");
		}
		sleep(0.5);
		@copy = removeElementsFrom2dArray(\@ships,1);
		$send_data = array2dToString(\@copy);
		$client_socket2->send($send_data);
		sleep(0.5);
		$client_socket2->send(sendHP(2));
		sleep(0.5);
	}
	$client_socket2->recv($x,1024);
	$client_socket2->recv($y,1024);
	if(shoot($x-1,$y-1)==1){
		$client_socket2->send("HIT\n");
	}
	else{
		$client_socket2->send("MISSED\n");
	}
	$client_socket1->send(sendHP(1));
	sleep(0.5);
	if(checkLost(1)==1){
		$client_socket2->send("You win\n");
		sleep(0.5);
		$client_socket1->send("You lose\n");
		sleep(0.5);
	}
	else{
		$client_socket1->send("Game is still going\n");
		sleep(0.5);
		$client_socket2->send("Game is still going\n");
		sleep(0.5);
	}
}