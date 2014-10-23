#!/usr/bin/perl

use Dancer;
use File::Spec;
use File::Slurp;
use Template;
use Net::Twitter;
 
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'layout'       => 'main';
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0; 

my $twitter;

# init method, to create the Net::Twitter object
my $consumer_key = ""; #Your Consumer Key
my $consumer_secret = ""; #Your consumer secret key
#my $callback_url = "http://localhost:3000/auth/twitter/callback";
my $callback_url;
my $callback_success;
my $callback_fail;
my $access_token = ""; # access token
my $access_secret = ""; #access token secret

$twitter = Net::Twitter->new({ 
     traits              => ['API::RESTv1_1', 'OAuth', 'WrapError'],
     consumer_key       => $consumer_key, 
     consumer_secret    => $consumer_secret,
     access_token        => $access_token ,
     access_token_secret => $access_secret,
     ssl                 => 1
});

hook before_template => sub {
       my $tokens = shift;
        
       $tokens->{'css_url'} = request->base . 'css/style.css';
       $tokens->{'home_url'} = uri_for('/');
       $tokens->{'get_status_url'} = uri_for('/get_status');
       $tokens->{'get_statistics_url'} = uri_for('/get_statistics');
};
 
get '/' => sub {
       template 'start.tt';
};
 
any ['get', 'post'] => '/get_status' => sub {
       my $err;
       my @status = qw();

       if ( request->method() eq "POST" ) {

	        my $name = params->{'screenname'};
		if (my $statuses = $twitter->user_timeline({ screen_name => $name, count => 20 }))
		{
			for my $stat ( @$statuses ) {
				#print "$status->{text}\n";
				push(@status,$stat->{text});
			}
			#return redirect '/get_status';
		}
		else
		{
   			 $err = "Invalid username";
			 @status = qw();
		}
       }
       # display get_status form
	template 'get_status.tt', {
		'err' => $err,
		'status' => \@status,
		
	};

};

any ['get', 'post'] => '/get_statistics' => sub {
       my $err;
       my @ids_array = qw();
       my @handles_array = qw();
       my %my_hash = ();

       if ( request->method() eq "POST" ) {

	        my $name1 = params->{'screenname1'};
	        my $name2 = params->{'screenname2'};
		if (my $ids_1 = $twitter->friends_ids({screen_name => $name1}))
		{
			my $id1_list = $ids_1->{ids};
			for my $id_1 ( @$id1_list ) {
				#print "$id_1\n";
				$my_hash{$id_1} = 1;
				#print "$my_hash{$id_1}\n";
			}
			
		}
		else
		{
   			 $err = "Username 1 invalid";
   			 #print "Here!!!!!\n";
			 @ids_array = qw();
			 @handles_array = qw();
			 goto Get_Method;
		}
		if (my $ids_2 = $twitter->friends_ids({screen_name => $name2}))
		{
			my $id2_list = $ids_2->{ids};
			my $common_users;
			#print "Entered user_2 Stats\n";
			for my $id_2 ( @$id2_list ) {
				if (exists $my_hash{$id_2}) {
					$common_users = $twitter->lookup_users({ user_id => $id_2 });
					for my $common_user (@$common_users){
						#print "$common_user->{name}\n"
						push(@ids_array,$common_user->{name});
						push(@handles_array,$common_user->{screen_name});
					}
					#print "$id_2\n";
				}
				#print "$id_2\n";
			}
		}
		else
		{
   			 $err = "Username 2 invalid";
			 @ids_array = qw();
			 @handles_array = qw();
			 goto Get_Method;
		}
       }
       # display get_statistics form
	Get_Method:
	template 'get_statistics.tt', {
		'err' => $err,
		'ids' => \@ids_array,
		'handles' => \@handles_array,
	
	};
};
 
start;
