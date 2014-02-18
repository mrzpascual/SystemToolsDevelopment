#!/usr/bin/perl
#
#==============================================================================
#       This script is maintained by the Application Integration Team.
#==============================================================================

use strict;
use warnings;
use XML::LibXML;
use Switch;

my $lookUpFile = "./remsh_lookup.xml";

my $parser = XML::LibXML->new();
my $xml = $parser->parse_file( $lookUpFile );

## Log files
my $report_log = "./report_log.tmp";
my $error_log = "./error_log.tmp";
my $file_count_log = "./file_count_log.tmp";

my $usage = "USAGE: \n$0 <process name>\n$0 <process name> <process name> ...\nProcess name and all required parameters needed for the cleanup process must be declared in the lookup file ($lookUpFile).\n";

my @sequence_array;
my $remote_user = "bldmgr";

## Start process.
if(!defined @ARGV){
  print $usage;
  exit;
}
foreach my $target (@ARGV){
  chomp($target);
  mainProcess($target);
}
&removeLogs;
# End process.

sub mainProcess{
  my (@servers, @dir_path, @filenames, @owners, @filesize, @mod_days, @mail_to);

  # Check disk usage.
  my $disk_usage_content;
  my $disk_usage_attr_enable;
  my $disk_usage_attr_used;

  my ($target_process) = shift;
  foreach my $process ($xml->findnodes( '//process' )){
    my ($process_name) = $process->getAttribute( 'name' );
    if($process_name eq $target_process){

      # Servers
      foreach my $server ($process->findnodes( './servers/server/' )){
        push(@servers, $server->textContent);
      }
      pushDefined(@servers);

      # Path | directory
      foreach my $path ($process->findnodes( './dir_path/path/' )){
        push(@dir_path, $path->textContent);
      }
      pushDefined(@dir_path);

      # Filename
      foreach my $file ($process->findnodes( './remove/by_filename/filename/' )){
        my $file_name_content = $file->textContent;
        if($file_name_content ne ""){
          my $fname_option = '-name';
          push(@filenames, $fname_option." ".$file_name_content);
	} 
      }
      pushDefined(@filenames);

      # Owner
      foreach my $owner ($process->findnodes( './remove/by_owner/owner/' )){
        my $owner_content = $owner->textContent;
        if($owner_content ne ""){
          my $owner_option = '-user';
          push(@owners, $owner_option." ".$owner_content);
	}
      }
      pushDefined(@owners);

      # File Size
      foreach my $file_size ($process->findnodes( './remove/by_file_size/file_size/' )){
        my $file_type = $file_size->getAttribute( 'type' );
        my $file_size_is = $file_size->getAttribute( 'size_is' );
        my $file_size_content = $file_size->textContent;
        if($file_size_content ne "" && $file_type ne "" && $file_size_is ne ""){
            my $size_option = '-size ';
            my $type_attr = fileSize($file_type);
            my $size_is_attr = moreOrLess($file_size_is);
            my $file_cat = $size_option.$size_is_attr.$file_size_content.$type_attr;
            push(@filesize, $file_cat);
	} 
      }
      pushDefined(@filesize);
      
      # Days modified
      foreach my $days ($process->findnodes( './remove/by_days/days/' )){
        my $days_modified = $days->getAttribute( 'modified' );
        my $days_content = $days->textContent;
        if($days_content ne "" && $days_modified ne ""){
            my $mtime_option = '-mtime ';
            my $modified_attr = moreOrLess($days_modified);
            my $days_cat = $mtime_option.$modified_attr.$days_content;
            push(@mod_days, $days_cat);
	} 
      }
      pushDefined(@mod_days);

      # Disk usage.
      foreach my $disk_usage ($process->findnodes( './disk_usage/' )){
        $disk_usage_attr_enable = $disk_usage->getAttribute( 'enable' );
        $disk_usage_attr_used = $disk_usage->getAttribute( 'used' );
        $disk_usage_content = $disk_usage->textContent;
      }

      # Report email.
      foreach my $mail_info ($process->findnodes( './mail/to/' )){
        my $parent_email = $mail_info->parentNode;
        my $email_attr_enable = $parent_email->getAttribute( 'enable' );
        my $mail_info_content = $mail_info->textContent;
        if(uc($email_attr_enable) eq "YES" && $mail_info_content ne ""){
          push(@mail_to, $mail_info_content); 
        }
      }
    }
  }

  # Assign sequence array.
  my (@param1, @param2, @param3, @param4, @param5, @param6);
  my $seq_length = @sequence_array;
  for (my $i = 0; $i < $seq_length; $i++){
    switch ($i){
      case 0 { @param1 = @{$sequence_array[$i]}}
      case 1 { @param2 = @{$sequence_array[$i]}}
      case 2 { @param3 = @{$sequence_array[$i]}}
      case 3 { @param4 = @{$sequence_array[$i]}}
      case 4 { @param5 = @{$sequence_array[$i]}}
      case 5 { @param6 = @{$sequence_array[$i]}}
    }
  }

  # Process log array.
  my @process;

  # Start - access arrays.
  my $p1_len = @param1;
  if($p1_len != 0){
    foreach my $p1 (@param1){
      my $p2_len = @param2;
      if($p2_len != 0){
        foreach my $p2 (@param2){
          push(@process, "Server: $p1");
          push(@process, "Directory: $p2");
          my $is_DiskUsage = getDiskUsage( $p2, $disk_usage_attr_used, $disk_usage_content);
          if(uc($disk_usage_attr_enable) eq "NO"){
            my $p3_len = @param3;
            if($p3_len != 0){
              foreach my $p3 (@param3){
                my $p4_len = @param4;
                if($p4_len != 0){
                  foreach my $p4 (@param4){
                    my $p5_len = @param5;
                    if($p5_len != 0) {
                      foreach my $p5 (@param5){
                        my $p6_len = @param6;
                        if($p6_len != 0){
                          foreach my $p6 (@param6){
                            `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 $p4 $p5 $p6 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                          }
                        } else {
                          `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 $p4 $p5 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                        }
                      }
                    } else {
                      `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 $p4 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                    }
                  }
                } else {
                  `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                }
              }
            } 

          # Disk usage enabled.
          } elsif (uc($disk_usage_attr_enable) eq "YES" && $is_DiskUsage eq "TRUE"){
            print $is_DiskUsage;
            my $p3_len = @param3;
            if($p3_len != 0){
              foreach my $p3 (@param3){
                my $p4_len = @param4;
                if($p4_len != 0){
                  foreach my $p4 (@param4){
                    my $p5_len = @param5;
                    if($p5_len != 0) {
                      foreach my $p5 (@param5){
                        my $p6_len = @param6;
                        if($p6_len != 0){
                          foreach my $p6 (@param6){
                            `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 $p4 $p5 $p6 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                          }
                        } else {
                          `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 $p4 $p5 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                        }
                      }
                    } else {
                      `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 $p4 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                    }
                  }
                } else {
                  `nohup remsh $p1 -n -l $remote_user 'find $p2 -xdev $p3 -print -exec sudo -a rm -rf {} \\;' 1>$file_count_log 2>>$error_log`;
                }
              }
            } 
          } 
          # END - Disk usage enabled.

          # Count files.
          my $file_count = `wc -l $file_count_log | awk '{print \$1}'`; 
          push(@process, "Total files deleted: $file_count");
        }
      } 
    }
  }
  # End - access arrays.

  # Send process report.
  processLog(@process);
  sendReport(@mail_to);
}
# End main process.

sub getDiskUsage{
  my $dir = $_[0];
  my $check = uc($_[1]);
  my $percent = $_[2];
  my $df = `df -k $dir | awk '{print \$4}'`;
  $df=~m/(\d+)/g;
  my $df_result = $1;
  chomp($dir, $check, $percent);
  if ($check eq "MORE"){
    if ($df_result ge $percent){
      return "TRUE"; 
    } else {
      return "FALSE"; 
    }
  } elsif ($check eq "LESS"){
    if ($df_result le $percent){
      return "TRUE"; 
    } else {
      return "FALSE"; 
    }
  }
}

sub sendReport{
  my @sendTo = @_;
  my $count_to = @sendTo;
  if ($count_to != 0){
    my $sendmail = '/usr/lib/sendmail';
    open(MAIL, "|$sendmail -oi -t");
      foreach my $to (@sendTo){
        print MAIL "To: $to\n";
      }
      print MAIL "Subject: Clean-up Report";
      print MAIL "\n";
      print MAIL "Process Summary ####################\n";
      foreach my $report (readFile($report_log)){
        print MAIL "$report\n";
      }
      print MAIL "";
      print MAIL "Error Report #######################\n";
      foreach my $error (readFile($error_log)){
        if($error=~/cannot chdir|cannot open/){
        } else {
          print MAIL "$error\n";
        }
      }
    close(MAIL);
  }
}

sub fileSize{
  my $size = uc($_[0]);
  my %file_size_list = ( "KB" , "k" ,
                         "MB" , "M" ,
                         "GB" , "G" );
  return $file_size_list{$size};
}

sub moreOrLess{
  my $identifier = uc($_[0]);
  my %file_more_less = ( "LESS" , "-" ,
                         "MORE" , "+" );
  return $file_more_less{$identifier};
}

sub pushDefined{
  if( defined @_ && $#_ >= 0){
    push(@sequence_array, \@_);
  }
}

sub readFile{
  my $infile=shift;
  my $lines;
    local($/, *FILE);
    $/=undef;
      open(FILE, $infile) || die "Cannot open file $infile";
        $lines=<FILE>;
      close(FILE);
    return $lines;
}

sub processLog{
    my @outfile = @_;
	open(OUT,">>$report_log") || die "Cannot open file $report_log";
          foreach my $out_ (@outfile){
	    print OUT $out_."\n";
          }
	close(OUT);
}

sub removeLogs{
  `rm $report_log $error_log $file_count_log`; }

exit 0;

