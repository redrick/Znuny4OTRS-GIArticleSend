# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

# get needed objects
my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UnitTestWebserviceObject = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $ZnunyHelperObject        = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $UnitTestEmailObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Email');

my %UserData = $HelperObject->TestUserDataGet(
    Groups => [ 'admin', 'users' ],
    Language => 'de'
);

$ZnunyHelperObject->_WebserviceCreate(
    SubDir => 'Znuny4OTRSGIArticleSend',
);

my $Response = $UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'GIArticleSend',
    Operation      => 'TicketCreate',
    Payload        => {
        Ticket => {
            Title        => 'Ticket Title',
            CustomerUser => 'someone@somehots.com',
            Type         => 'Unclassified',
            Queue        => 'Misc',
            State        => 'open',
            Priority     => '3 normal',
            Owner        => 'root@localhost',
            Responsible  => 'root@localhost',
        },
        Article => {
            Subject              => 'Article subject äöüßÄÖÜ€ис',
            Body                 => 'Article body !"Â§$%&/()=?Ã<U+009C>*Ã<U+0084>Ã<U+0096>L:L@,.-',
            AutoResponseType     => 'auto reply',
            IsVisibleForCustomer => 1,
            CommunicationChannel => 'Email',
            SenderType           => 'agent',
            From                 => 'enjoy@otrs.com',
            Charset              => 'utf8',
            MimeType             => 'text/plain',
            HistoryType          => 'NewTicket',
            HistoryComment       => '% % ',
            ArticleSend          => 1,
            To                   => 'rs+GIArticleSend@znuny.com',
        },
        UserLogin => $UserData{UserLogin},
        Password  => $UserData{UserLogin},
    },
);

$Self->True(
    $Response->{Success},
    'ticket created successfully',
);
$Self->True(
    $Response->{Data}->{TicketID},
    'ticket creation result contains ticket id',
);

my @Emails = $UnitTestEmailObject->EmailGet();

$UnitTestEmailObject->EmailValidate(
    UnitTestObject => $Self,
    Message        => 'ticket creation triggered ArticleSend functionality.',
    Email          => \@Emails,
    ToArray        => 'rs+GIArticleSend@znuny.com',
);

#
# test with no To-email
#

$UnitTestEmailObject->MailCleanup();

$Response = $UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'GIArticleSend',
    Operation      => 'TicketCreate',
    Payload        => {
        Ticket => {
            Title        => 'Ticket Title',
            CustomerUser => 'someone@somehots.com',
            Type         => 'Unclassified',
            Queue        => 'Misc',
            State        => 'open',
            Priority     => '3 normal',
            Owner        => 'root@localhost',
            Responsible  => 'root@localhost',
        },
        Article => {
            Subject              => 'Article subject äöüßÄÖÜ€ис',
            Body                 => 'Article body !"Â§$%&/()=?Ã<U+009C>*Ã<U+0084>Ã<U+0096>L:L@,.-',
            AutoResponseType     => 'auto reply',
            IsVisibleForCustomer => 1,
            CommunicationChannel => 'Email',
            SenderType           => 'agent',
            From                 => 'enjoy@otrs.com',
            Charset              => 'utf8',
            MimeType             => 'text/plain',
            HistoryType          => 'NewTicket',
            HistoryComment       => '% % ',
            ArticleSend          => 1,
        },
        UserLogin => $UserData{UserLogin},
        Password  => $UserData{UserLogin},
    },
);

$Self->Is(
    $Response->{Data}->{Error}->{ErrorCode},
    'TicketCreate.InvalidParameter',
    'ticket creation failed',
);

@Emails = $UnitTestEmailObject->EmailGet();
$Self->False(
    @Emails ? 1 : 0,
    'No emails sent out',
);

1;
