package PublishTwilog::Plugin;
use strict;
use base qw(MT::Plugin);
use MT;
use MT::Util qw( start_end_day epoch2ts format_ts trim );
use MT::I18N;
use Data::Dumper;

## DEBUC CODE
sub doLog {
    my ( $msg, $class ) = @_;
    return unless defined($msg);
    use MT::Log;
    my $log = MT::Log->new;
    $log->message($msg);
    $log->level( MT::Log::DEBUG() );
    $log->class($class) if $class;
    $log->save or die $log->errstr;
}

sub plugin {
    return MT->component('PublishTwilog');
}

sub _hdlr_auto_twilog_entry {
    my $blog_iter = MT::Blog->load_iter();
    my $plugin    = plugin();
    while ( my $blog = $blog_iter->() ) {
        if ( my $blog_id =
            $plugin->get_config_value( 'blogid', 'blog:' . $blog->id ) )
        {
            &_twilog_entry($blog) if ( $blog_id eq $blog->id );
        }
    }
}

sub _twilog_entry {
    my $blog    = shift;
    my $plugin  = plugin();
    my $blog_id = $plugin->get_config_value( 'blogid', 'blog:' . $blog->id );
    my $username =
      $plugin->get_config_value( 'twitter_username', 'blog:' . $blog_id );
    my $author_id =
      $plugin->get_config_value( 'author_id', 'blog:' . $blog_id );
    my $category_id =
      $plugin->get_config_value( 'category_id', 'blog:' . $blog_id );
    my $status  = $plugin->get_config_value( 'status',  'blog:' . $blog_id );
    my $title   = $plugin->get_config_value( 'title',   'blog:' . $blog_id );
    my $display = $plugin->get_config_value( 'display', 'blog:' . $blog_id );
    my $start = start_end_day( epoch2ts( $blog, time - ( 60 * 60 * 24 * 2 ) ) );
    $start = format_ts( '%Y%m%d', $start, $blog );
    $start =~ s/\d{2}//;
    my $ago = start_end_day( epoch2ts( $blog, time - ( 60 * 60 * 24 ) ) );
    my $end = format_ts( '%Y%m%d', $ago, $blog );
    $end =~ s/\d{2}//;
    my $date = format_ts( '%Y-%m-%d', $ago, $blog );
    $title .= " " . $date;
    my $body =
      MT::I18N::utf8_off( '<div class="tl-tweets" id="d' . $end . '">' );
    $body .= get_data( $username, $display, $start, $end );
    $body .= MT::I18N::utf8_off(
'<p>via <a href="http://twilog.org/" title="Twilog - Twitterのつぶやきをブログ形式で保存">Twilog - Twitterのつぶやきをブログ形式で保存</a></p>'
    );

    my $entry = MT::Entry->new;
    $entry->blog_id($blog_id);
    $entry->author_id($author_id);
    $entry->status($status);
    $entry->class('entry');
    $entry->allow_comments( $blog->allow_comments_default );
    $entry->allow_pings( $blog->allow_pings_default );
    $entry->title($title);
    $entry->text($body);
    $entry->save
      or die 'Error saving entry', $entry->errstr;
    my $entry_id = $entry->id;
    my $place    = MT::Placement->new;
    $place->entry_id($entry_id);
    $place->blog_id($blog_id);
    $place->category_id($category_id);
    $place->is_primary(1);
    $place->save
      or die 'Error saving placement', $place->errstr;

    my $pub = MT::WeblogPublisher->new();
    $pub->rebuild_entry(
        Entry             => $entry,
        BuildDependencies => 1,
        NoIndexes         => 1
    );
    $pub->rebuild_indexes( Blog => $blog );

    MT->log(
        {
            message => $plugin->name
              . ': EntryID-'
              . $entry_id . ':'
              . $title
              . ' published',
            blog_id => $blog->id,
            level   => MT::Log::INFO(),
        }
    );
}

sub get_data {
    my ( $username, $display, $start, $end ) = @_;
    my $plugin  = plugin();
    my $pattern = qq/"d$end">(.*?)<div class="p-link">/;
    require MT::I18N;
    my $charset = MT::ConfigMgr->instance->PublishCharset;
    my $ua =
      MT->new_ua( { agent => join( "/", $plugin->name, $plugin->version ) } );
    my $url =
        ( $display == '1' ) ? 'http://twilog.org/' . $username . '/norep'
      : ( $display == '2' ) ? 'http://twilog.org/' . $username . '/nomen'
      :                       'http://twilog.org/' . $username;
    my $res = $ua->get($url);

    if ( $res->is_success ) {
        my $html = $res->content;
        $html =~ s/\n//g;
        if ( $html =~ /$pattern/g ) {
            return MT::I18N::encode_text( $1, 'utf8', $charset );
        }
    }
    else {
        MT->log(
            {
                message => $plugin->translate('as_wget_error')
                  . $res->status_line,
                class => 'system',
                level => MT::Log::ERROR(),
            }
        );
        die $plugin->translate('as_wget_error') . $res->status_line;
    }
}
1;
