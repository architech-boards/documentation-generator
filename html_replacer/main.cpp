#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <string.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <getopt.h>

#define LANG_OPTION             ":lang: "
#define LANG_DEFAULT            "markup"

#define START_OPTION            ":start: "
#define START_DEFAULT           "1"

#define LINE_MARKER             "| "
#define LINE_MARKER_EMPTY       "|"

#define LOG_ERROR_PREFIX        " ERROR: "
#define LOG_WARNING_PREFIX      " WARNING: "
#define LOG_INFO_PREFIX         " INFO: "

using namespace std;

typedef enum {OUT_OF_BLOCK, FOUND_DIRECTIVE, FOUND_OPTION, FOUND_SPACE, FOUND_CONTENT } parser_state_t;
typedef enum {LOG_ERROR = 0, LOG_WARNING, LOG_INFO} log_t;

log_t
    debug_level                         = LOG_ERROR;

string to_string(int number)
{
   stringstream ss;
   ss << number;
   return ss.str();
}

string
find_and_replace( string text, string to_find, string to_replace )
{
    if( ( to_find.size() > text.size() ) || ( text.size() == 0 ) )
    {
        return text;
    }
    string
        current_string,
        to_return;
    int
        i;
    to_return                           = "";
    for( i = 0; i < text.size() - to_find.size() + 1; )
    {
        current_string                  = text.substr( i, to_find.size() );
        if( current_string == to_find )
        {
            to_return                   += to_replace;
            i                           += to_find.size();
        }else{
            to_return                   += text[ i ];
            i++;
        }
    }
    if( i != text.size() ){
        to_return                       += text.substr( i );
    }
    return to_return;
}

string
get_indentation( string text )
{
    for( int i = 0; i < text.size(); i++ )
    {
        if( text[ i ] != ' ' && text[ i ] != '\t' )
        {
            if( i == 0 )
            {
                return "";
            }
            else
            {
                return text.substr( 0, i );
            }
        }
    }
    return text;
}

string
trim_string_left( string text )
{
    for( int i = 0; i < text.size(); i++ )
    {
        if( text[ i ] != ' ' && text[ i ] != '\t' )
        {
            return text.substr( i );
        }
    }
    return "";
}

string
trim_string_right( string text )
{
    for( int i = text.size() - 1; i >= 0; i-- )
    {
        if( text[ i ] != ' ' && text[ i ] != '\t' )
        {
            return text.substr( 0, i + 1 );
        }
    }
    return "";
}

string
trim_string( string text )
{
    return trim_string_right( trim_string_left( text ) );
}

bool
ends_with( string text, string pattern )
{
    if( text.rfind( pattern ) != ( text.size() - pattern.size() ) )
        return false;
    return true;
}

bool
starts_with( string text, string pattern )
{
    if( text.find( pattern ) != 0 )
        return false;
    return true;
}

bool
is_integer( string text )
{
    for( int i = 0; i < text.size(); i++ )
    {
        if( text[ i ] < '0' || text[ i ] > '9' )
        {
            if( ( i != 0 ) || ( ( text[ i ] != '+' ) && ( text[ i ] != '-' ) ) )
            {
                return false;
            }
        }
    }
    return true;
}

string
fix_code_format( string input, string indentation )
{
    string
        output;
    output                              = find_and_replace( input,  "<",  "&lt;" );
    output                              = find_and_replace( output, ">",  "&gt;" );
    output                              = find_and_replace( output, "\n", "\n" + indentation );
    return output;
}

string
process_content( string directive, string title, string differentiator, string block, string content, string lang, string start )
{
    static int
        current_box                     = 1;
    string
        raw                             = "",
        id                              = differentiator + to_string( current_box );
    if(
        ( lang != "markup" )        &&
        ( lang != "css" )           &&
        ( lang != "clike" )         &&
        ( lang != "javascript" )    &&
        ( lang != "java" )          &&
        ( lang != "php" )           &&
        ( lang != "coffeescript" )  &&
        ( lang != "scss" )          &&
        ( lang != "bash" )          &&
        ( lang != "c" )             &&
        ( lang != "cpp" )           &&
        ( lang != "python" )        && 
        ( lang != "sql" )           &&
        ( lang != "groovy" )        &&
        ( lang != "http" )          && 
        ( lang != "ruby" )          &&
        ( lang != "gherkin" )       &&
        ( lang != "csharp" )        &&
        ( lang != "go" )            &&
        ( lang != "nsis" )
    )
    {
        return block;
    }
    if( !is_integer( start ) )
    {
        return block;
    }
    raw                                 = fix_code_format( content, " " );
    raw                                 =   string() + "\n.. raw:: html\n" +
                                            "\n" +
                                            " <div>\n" +
                                            " <div><b class=\"admonition-" + directive + "\">&nbsp;&nbsp;" + title + "&nbsp;&nbsp;</b>&nbsp;&nbsp;<a style=\"float: right;\" href=\"javascript:select_text( '" + id + "' );\">select</a></div>\n" +
                                            " <pre class=\"line-numbers pre-replacer\" data-start=\"" + start + "\"><code id=\"" + id + "\" class=\"language-" + lang + "\">" + raw + "</code></pre>\n" +
                                            " <script src=\"_static/prism.js\"></script>\n" +
                                            " <script src=\"_static/select_text.js\"></script>\n" +
                                            " </div>\n";
    current_box++;
    return raw;
}

void
print_log( string message, log_t log_level )
{
    int
        prefix_size;
    if( log_level > debug_level )
        return;
    switch( log_level )
    {
        case LOG_ERROR:
            cout << LOG_ERROR_PREFIX;
            prefix_size                     = strlen( LOG_ERROR_PREFIX );
            break;
        case LOG_WARNING:
            cout << LOG_WARNING_PREFIX;
            prefix_size                     = strlen( LOG_WARNING_PREFIX );
            break;
        case LOG_INFO:
            cout << LOG_INFO_PREFIX;
            prefix_size                     = strlen( LOG_INFO_PREFIX );
            break;
    }
    cout << find_and_replace( message, "\n", "\n" + string( prefix_size, ' ' ) ) << endl;
}

void
print_output( string message )
{
    if( debug_level != LOG_INFO )
    {
        cout << message;
    }
}

struct option
    long_options[]                      =
{
    { "help",                   no_argument,            0,      'h' },
    { "filepath",               required_argument,      0,      'f' },
    { "admonition-name",        required_argument,      0,      'a' },
    { "title",                  required_argument,      0,      't' },
    { "differentiator",         required_argument,      0,      'u' },
    { "debug-level",            required_argument,      0,      'd' },
    { 0,                        0,                      0,       0  },
};

void print_usage( string program_name )
{
    cout << endl;
    cout << " This program takes a .rst file as input, it looks for admonitions with the given name and," << endl;
    cout << " if the content starts with \"| \" on every line, the program will replace them with raw html" << endl;
    cout << " that enables a cleaner wiew of code lines. You need to provide a string that will help this" << endl;
    cout << " program to uniquely identify html elements inside the final web page." << endl;
    cout << endl;
    cout << " Usage: " << program_name << " [OPTIONS]" << endl;
    cout << endl;
    cout << " OPTIONS:" << endl;
    cout << "   -h  --help                          Display this help and exit." << endl;
    cout << "   -f  --filepath <filepath>           Input file filepath." << endl;
    cout << "   -a  --admonition-name <name>        The name of the admonition to replace (e.g. host)." << endl;
    cout << "   -t  --title <box title>             The box title to display inside in the final HTML page" << endl;
    cout << "                                       (e.g. Host)." << endl;
    cout << "   -u  --differentiator <unique-label> A string to help this program uniquely identify an HTML" << endl;
    cout << "                                       element inside the final page." << endl;
    cout << "   -d  --debug-level <level>           The level of debug you want to enable:" << endl;
    cout << "                                           0 display just errors," << endl;
    cout << "                                           1 display errors and warnings," << endl;
    cout << "                                           2 display all the debug prints and suppress the normal" << endl;
    cout << "                                             out." << endl;
    cout << "                                       This parameter is optional." << endl;
}

bool
parse_command_line(
            int     argc,
            char    **argv,
            string  &filepath,
            string  &directive_name,
            string  &title,
            string  &differentiator,
            log_t   &debug_level
)
{
    int
        c,
        option_index                    = 0;
    string
        debug_level_string              = "";
    int
        debug_level_number              = 0;
    bool
        error                           = false;

    filepath                            = "";
    directive_name                      = "";
    title                               = "";
    differentiator                      = "";

    while( 1 )
    {
        c                               = getopt_long( argc, argv, "hf:a:t:u:d:", long_options, &option_index );
        if( c == -1 )
        {
            break;
        }
        switch( c )
        {
            case 'h':
                print_usage( string( argv[ 0 ] ) );
                exit( 0 );
            case 'f':
                filepath                = string( optarg );
                break;
            case 'a':
                directive_name          = string( optarg );
                break;
            case 't':
                title                   = string( optarg );
                break;
            case 'u':
                differentiator          = string( optarg );
                break;
            case 'd':
                debug_level_string      = string( optarg );
                break;
            default:
                print_log( "Unrecognized option \"" + string( 1, c ) + "\".", LOG_ERROR );
                error                   = true;
        }
    }
    if( filepath == "" )
    {
        error                           = true;
        print_log( "-f option missing.", LOG_ERROR );
    }
    if( directive_name == "" )
    {
        error                           = true;
        print_log( "-a option missing.", LOG_ERROR );
    }
    if( title == "" )
    {
        error                           = true;
        print_log( "-t option missing.", LOG_ERROR );
    }
    if( differentiator == "" )
    {
        error                           = true;
        print_log( "-u option missing.", LOG_ERROR );
    }
    if( debug_level_string != "" )
    {
        if( !is_integer( debug_level_string ) )
        {
            print_log( "-d option with invalid value.", LOG_ERROR );
            error                       = true;
        }
        else
        {
            debug_level_number          = atoi( debug_level_string.c_str() );
            if( ( debug_level_number < LOG_ERROR ) || ( debug_level_number > LOG_INFO ) )
            {
                print_log( "-d option with invalid value.", LOG_ERROR );
                error                   = true;
            }
            else
            {
                debug_level             = (log_t)debug_level_number;
            }
        }
    }
    return !error;
}

int
main( int argc, char **argv )
{
    string
        filepath                            = "",
        directive_name                      = "",
        title                               = "",
        differentiator                      = "";
    if( !parse_command_line( argc, argv, filepath, directive_name, title, differentiator, debug_level ) )
    {
        print_usage( string( argv[ 0 ] ) );
        return 1;
    }

    string
        directive                           = ".. " + directive_name + "::",
        current_line                        = "",
        tmp                                 = "",
        block                               = "",
        block_indentation                   = "",
        content                             = "",
        lang                                = "",
        start                               = "";
    bool
        first_line                          = true,
        start_found                         = false,
        lang_found                          = false;
    ifstream
        input( filepath.c_str() );
    parser_state_t
        state                               = OUT_OF_BLOCK;

    if( !input.is_open() )
    {
        print_log( "Impossible to open file \"" + filepath + "\". Aborting.", LOG_ERROR );
        return 1;
    }

    while( getline( input, current_line ) )
    {
        print_log( "current_line: " + current_line, LOG_INFO );
        switch( state )
        {
            case OUT_OF_BLOCK:
                print_log( "Inside OUT_OF_BLOCK.", LOG_INFO );
                // This means that we could parse the directive or nothing interesting
                block                       = "";
                content                     = "";
                lang                        = LANG_DEFAULT;
                lang_found                  = false;
                start                       = START_DEFAULT;
                start_found                 = false;
                block_indentation           = "";
                if( starts_with( current_line, directive ) )
                {
                    state                   = FOUND_DIRECTIVE;
                    print_log( "Directive \"" + directive_name + "\" found.", LOG_INFO );
                    if( !first_line )
                    {
                        block               += "\n";
                    }
                    block                   += current_line;
                }
                else
                {
                    print_log( "No directive found.", LOG_INFO );
                    if( !first_line )
                    {
                        print_output( "\n" );
                    }
                    print_output( current_line );
                }
                break;            
            case FOUND_DIRECTIVE:
                print_log( "Inside FOUND_DIRECTIVE.", LOG_INFO );
                // This means we should look for an option, an empty line or the first line to process
                block                       += "\n" + current_line;
                if( trim_string( current_line ) == "" )
                { // Found an empty line
                    state                   = FOUND_SPACE;
                    print_log( "Found an empty line.", LOG_INFO );
                }
                else
                { 
                    bool
                        error               = false;
                    block_indentation       = get_indentation( current_line );
                    if( block_indentation == "" )
                    { // Wrong indentation, skip
                        print_log( "Wrong indentation.", LOG_WARNING );
                        error               = true;
                    }
                    else
                    { // It can be an option or a line with data
                        tmp                 = trim_string( current_line );
                        if( starts_with( tmp, LANG_OPTION ) )
                        {
                            print_log( "Lang option found...", LOG_INFO );
                            if( tmp.size() > string( LANG_OPTION ).size() )
                            {
                                print_log( "Lang option has content.", LOG_INFO );
                                lang        = tmp.substr( string( LANG_OPTION ).size() );
                                state       = FOUND_OPTION;
                                lang_found  = true;
                            }
                            else
                            {
                                print_log( "Lang option has no value.", LOG_WARNING );
                                error       = true;
                            }
                        }
                        else if( starts_with( tmp, START_OPTION ) )
                        {
                            print_log( "Start option found...", LOG_INFO );
                            if( tmp.size() > string( START_OPTION ).size() )
                            {
                                print_log( "Start option has content.", LOG_INFO );
                                start       = tmp.substr( string( START_OPTION ).size() );
                                state       = FOUND_OPTION;
                                start_found = true;
                            }
                            else
                            {
                                print_log( "Start option has no value.", LOG_WARNING );
                                error       = true;
                            }
                        }
                        else if( starts_with( tmp, LINE_MARKER ) )
                        {
                            print_log( "Line marker found.", LOG_INFO );
                            if( tmp.size() > string( LINE_MARKER ).size() )
                            {
                                content     = tmp.substr( string( LINE_MARKER ).size() );
                                state       = FOUND_CONTENT;
                            }
                        }
                        else if( tmp == string( LINE_MARKER_EMPTY ) )
                        {
                            print_log( "Line marker found.", LOG_INFO );
                            state           = FOUND_CONTENT;
                        }
                        else
                        {
                            print_log( "Unrecognized line.", LOG_WARNING );
                            error           = true;
                        }
                    }
                    if( error )
                    {
                        print_output( block );
                        state               = OUT_OF_BLOCK;
                    }                
                }
                break;
            case FOUND_OPTION:
                print_log( "Inside FOUND_OPTION.", LOG_INFO );
                // We can expect another option, an empty line or a line with data
                block                       += "\n" + current_line;
                tmp                         = trim_string( current_line );
                if( tmp == "" )
                { // Found an empty line
                    print_log( "Found an empty line.", LOG_INFO );
                    state                   = FOUND_SPACE;
                }
                else
                {
                    bool
                        error               = false;
                    if( block_indentation == "" )
                    {
                        block_indentation   = get_indentation( current_line );
                    }
                    if( ( block_indentation == "" ) || ( block_indentation != get_indentation( current_line ) ) )
                    { // Wrong indentation, skip
                        print_log( "Wrong indentation found.", LOG_WARNING );
                        error               = true;
                    }
                    else
                    { // It can be an option or a line with data
                        if( starts_with( tmp, LANG_OPTION ) )
                        {
                            print_log( "Lang option found...", LOG_INFO );
                            if( lang_found )
                            {
                                print_log( "Lang option was already found.", LOG_WARNING );
                                error       = true;
                            }
                            else if( tmp.size() > string( LANG_OPTION ).size() )
                            {
                                print_log( "Lang option has a value.", LOG_INFO );
                                lang        = tmp.substr( string( LANG_OPTION ).size() );
                                state       = FOUND_OPTION;
                                lang_found  = true;
                            }
                            else
                            {
                                print_log( "Lang option has no value.", LOG_WARNING );
                                error       = true;
                            }
                        }
                        else if( starts_with( tmp, START_OPTION ) )
                        {
                            print_log( "Start option found...", LOG_INFO );
                            if( start_found )
                            {
                                print_log( "Start option was already found.", LOG_WARNING );
                                error       = true;
                            }
                            else if( tmp.size() > string( START_OPTION ).size() )
                            {
                                print_log( "Start option has a value.", LOG_INFO );
                                start       = tmp.substr( string( START_OPTION ).size() );
                                state       = FOUND_OPTION;
                                start_found = true;
                            }
                            else
                            {
                                print_log( "Start option has no value.", LOG_WARNING );
                                error       = true;
                            }
                        }
                        else if( starts_with( tmp, LINE_MARKER ) )
                        {
                            print_log( "Line marker found.", LOG_INFO );
                            if( tmp.size() > string( LINE_MARKER ).size() )
                            {
                                content     = tmp.substr( string( LINE_MARKER ).size() );
                                state       = FOUND_CONTENT;
                            }
                        }
                        else if( tmp == string( LINE_MARKER_EMPTY ) )
                        {
                            print_log( "Line marker found.", LOG_INFO );
                            state           = FOUND_CONTENT;
                        }
                        else
                        {
                            print_log( "Unrecognized line", LOG_WARNING );
                            error           = true;
                        }
                    }
                    if( error )
                    {
                        print_output( block );
                        state               = OUT_OF_BLOCK;
                    }
                }

                break;
            case FOUND_SPACE:
                print_log( "Inside FOUND_SPACE.", LOG_INFO );
                // Now can expect another empty line or a line with useful data
                block                       += "\n" + current_line;
                tmp                         = trim_string( current_line );
                if( tmp == "" )
                {
                    print_log( "Empty line found", LOG_INFO );
                    state                   = FOUND_SPACE;
                }
                else 
                {
                    bool
                        error               = false;
                    if( block_indentation == "" )
                    {
                        block_indentation   = get_indentation( current_line );
                    }
                    if( ( block_indentation == "" ) || ( get_indentation( current_line ) != block_indentation ) )
                    {                   
                        print_log( "Wrong indentation.", LOG_WARNING );
                        error               = true;
                    }
                    else if( starts_with( tmp, LINE_MARKER ) )
                    {
                        print_log( "Line marker found.", LOG_INFO );
                        if( tmp.size() > string( LINE_MARKER ).size() )
                        {
                            content         = tmp.substr( string( LINE_MARKER ).size() );
                            state           = FOUND_CONTENT;
                        }
                    }
                    else if( tmp == string( LINE_MARKER_EMPTY ) )
                    {
                        print_log( "Line marker found.", LOG_INFO );
                        state           = FOUND_CONTENT;
                    }
                    else
                    {
                        print_log( "Unrecognized line.", LOG_INFO );
                        error               = true;
                    }
                    if( error )
                    {
                        print_output( block );
                        state               = OUT_OF_BLOCK;
                    }
                }
                break;
            case FOUND_CONTENT:
                print_log( "Inside FOUND_CONTENT.", LOG_INFO );
                // Now we can expect another line of data or the end of the data block
                block                       += "\n" + current_line;
                tmp                         = trim_string( current_line );
                {
                    bool
                        error               = false,
                        the_end             = false;
                    if( tmp == "" )
                    {                        
                        print_log( "Found empty line.", LOG_INFO );
                        the_end             = true;
                    }
                    else
                    {
                        if( get_indentation( current_line ) != block_indentation )
                        {
                            print_log( "Wrong indentation.", LOG_WARNING );
                            error           = true;
                        }
                        else if( !( starts_with( tmp, LINE_MARKER ) || ( tmp == string( LINE_MARKER_EMPTY ) ) ) )
                        {
                            print_log( "Line marker not found.", LOG_WARNING );
                            error           = true;
                        }
                        else
                        {
                            print_log( "Found line marker.", LOG_INFO );
                            if( tmp.size() > string( LINE_MARKER ).size() )
                            {
                                content     += "\n" + tmp.substr( string( LINE_MARKER ).size() );
                            }
                            else
                            {
                                content     += "\n";
                            }
                        }
                    }
                    if( error )
                    {
                        print_output( block );
                        state               = OUT_OF_BLOCK;
                    }
                    else if( the_end )
                    {
                        print_log( "Admonition block accepted.", LOG_INFO );
                        state               = OUT_OF_BLOCK;
                        print_output( process_content( directive_name, title, differentiator, block, content, lang, start ) );
                    }
                }
                break;
        }
        first_line                          = false;
    }

    switch( state )
    {
        case OUT_OF_BLOCK:
            break;
        case FOUND_DIRECTIVE:
        case FOUND_OPTION:
        case FOUND_SPACE:
            print_log( "Rejecting last block", LOG_WARNING );
            print_output( block );
            break;
        case FOUND_CONTENT:
            print_log( "Accepting last block", LOG_INFO );
            print_output( process_content( directive_name, title, differentiator, block, content, lang, start ) );
            break;
    }

    input.close();
    return 0;
}
