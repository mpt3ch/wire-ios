// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


@import MobileCoreServices;

#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Private.h"

#import "Wire-Swift.h"


@import FLAnimatedImage;

static NSString* ZMLogTag ZM_UNUSED = @"UI";


@implementation ConversationInputBarViewController


/**
 init with a ZMConversation objcet

 @param conversation provide nil only for tests
 @return a ConversationInputBarViewController
 */
- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super init];
    if (self) {
        [self setupAudioSession];

        if (conversation != nil) {
            self.conversation = conversation;
            self.sendController = [[ConversationInputBarSendController alloc] initWithConversation:self.conversation];
            self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
            self.typingObserverToken = [conversation addTypingObserver:self];
        }

        self.sendButtonState = [[ConversationInputBarButtonState alloc] init];

        [self setupNotificationCenter];

        [self setupInputLanguageObserver];

        self.notificationFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
        self.impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];

        [self setupViews];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCallStateObserver];
    [self setupAppLockedObserver];
    
    [self createSingleTapGestureRecognizer];


    if (self.conversation.hasDraftMessage) {
        [self.inputBar.textView setDraftMessage:self.conversation.draftMessage];
    }

    [self configureAudioButton:self.audioButton];
    [self configureMarkdownButton];
    [self configureMentionButton];
    [self configureEphemeralKeyboardButton:self.hourglassButton];
    [self configureEphemeralKeyboardButton:self.ephemeralIndicatorButton];
    
    [self.sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.photoButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoButton addTarget:self action:@selector(videoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.sketchButton addTarget:self action:@selector(sketchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.uploadFileButton addTarget:self action:@selector(docUploadPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pingButton addTarget:self action:@selector(pingButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.gifButton addTarget:self action:@selector(giphyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton addTarget:self action:@selector(locationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.conversationObserverToken == nil && self.conversation != nil) {
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
    }

    if (self.userObserverToken == nil &&
        self.conversation.connectedUser != nil
        && ZMUserSession.sharedSession != nil) {
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:self.conversation.connectedUser inUserSession:ZMUserSession.sharedSession];
    }
    
    [self updateAccessoryViews];
    [self updateInputBarVisibility];
    [self updateTypingIndicator];
    [self updateWritingStateAnimated:NO];
    [self updateButtonIcons];
    [self updateAvailabilityPlaceholder];

    [self setInputLanguage];
    [self setupStyle];
    
    if (@available(iOS 11.0, *)) {
        UIDropInteraction *interaction = [[UIDropInteraction alloc] initWithDelegate:self];
        [self.inputBar.textView addInteraction:interaction];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRightAccessoryView];
    [self.inputBar updateReturnKey];
    [self.inputBar updateEphemeralState];
    [self updateMentionList];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.inputBar.textView endEditing:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self endEditingMessageIfNeeded];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.ephemeralIndicatorButton.layer.cornerRadius = CGRectGetWidth(self.ephemeralIndicatorButton.bounds) / 2;
}

- (void)createSingleTapGestureRecognizer
{
    self.singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTapGestureRecognizer.enabled = NO;
    self.singleTapGestureRecognizer.delegate = self;
    self.singleTapGestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.singleTapGestureRecognizer];
}

- (void)updateRightAccessoryView
{
    [self updateEphemeralIndicatorButtonTitle:self.ephemeralIndicatorButton];
    
    NSString *trimmed = [self.inputBar.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    [self.sendButtonState updateWithTextLength:trimmed.length
                                       editing:nil != self.editingMessage
                                   markingDown:self.inputBar.isMarkingDown
                            destructionTimeout:self.conversation.messageDestructionTimeoutValue
                              conversationType:self.conversation.conversationType
                                          mode:self.mode
               syncedMessageDestructionTimeout:self.conversation.hasSyncedMessageDestructionTimeout];

    self.sendButton.hidden = self.sendButtonState.sendButtonHidden;
    self.hourglassButton.hidden = self.sendButtonState.hourglassButtonHidden;
    self.ephemeralIndicatorButton.hidden = self.sendButtonState.ephemeralIndicatorButtonHidden;
    self.ephemeralIndicatorButton.enabled = self.sendButtonState.ephemeralIndicatorButtonEnabled;

    [self.ephemeralIndicatorButton setBackgroundImage:self.conversation.timeoutImage forState:UIControlStateNormal];
    [self.ephemeralIndicatorButton setBackgroundImage:self.conversation.disabledTimeoutImage
                                             forState:UIControlStateDisabled];
}

- (void)updateMentionList
{
    [self triggerMentionsIfNeededFrom: self.inputBar.textView with:nil];
}


#pragma mark - Input views handling

- (void)setMode:(ConversationInputBarViewControllerMode)mode
{
    if (_mode == mode) {
        return;
    }
    _mode = mode;
    
    switch (mode) {
        case ConversationInputBarViewControllerModeTextInput:
            [self asssignInputController: nil];
            self.inputController = nil;
            self.singleTapGestureRecognizer.enabled = NO;
            [self selectInputControllerButton:nil];
            break;
    
        case ConversationInputBarViewControllerModeAudioRecord:
            [self clearTextInputAssistentItemIfNeeded];
            
            if (self.inputController == nil || self.inputController != self.audioRecordKeyboardViewController) {
                if (self.audioRecordKeyboardViewController == nil) {
                    self.audioRecordKeyboardViewController = [[AudioRecordKeyboardViewController alloc] init];
                    self.audioRecordKeyboardViewController.delegate = self;
                }

                [self asssignInputController: self.audioRecordKeyboardViewController];
            }

            self.singleTapGestureRecognizer.enabled = YES;
            [self selectInputControllerButton:self.audioButton];
            break;
            
        case ConversationInputBarViewControllerModeCamera:
            [self clearTextInputAssistentItemIfNeeded];
            
            if (self.inputController == nil || self.inputController != self.cameraKeyboardViewController) {
                if (self.cameraKeyboardViewController == nil) {
                    [self createCameraKeyboardViewController];
                }

                [self asssignInputController: self.cameraKeyboardViewController];
            }
            
            self.singleTapGestureRecognizer.enabled = YES;
            [self selectInputControllerButton:self.photoButton];
            break;

        case ConversationInputBarViewControllerModeTimeoutConfguration:
            [self clearTextInputAssistentItemIfNeeded];

            if (self.inputController == nil || self.inputController != self.ephemeralKeyboardViewController) {
                if (self.ephemeralKeyboardViewController == nil) {
                    [self createEphemeralKeyboardViewController];
                }

                [self asssignInputController: self.ephemeralKeyboardViewController];
            }

            self.singleTapGestureRecognizer.enabled = YES;
            [self selectInputControllerButton:self.hourglassButton];
            break;


    }
    
    [self updateRightAccessoryView];
}

- (void)selectInputControllerButton:(IconButton *)button
{
    for (IconButton *otherButton in @[self.photoButton, self.audioButton, self.hourglassButton]) {
        otherButton.selected = [button isEqual:otherButton];
    }
}

- (void)clearTextInputAssistentItemIfNeeded
{
    if (nil != [UITextInputAssistantItem class]) {
        UITextInputAssistantItem *item = self.inputBar.textView.inputAssistantItem;
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
    }
}

@end
