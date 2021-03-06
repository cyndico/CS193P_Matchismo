//
//  CardGameViewController.m
//  Matchismo
//
//  Created by Ronny Webers on 11/02/13.
//  Copyright (c) 2013 AM2 Consulting BVBA. All rights reserved.
//

#import "CardGameViewController.h"
#import "PlayingCardDeck.h"
#import "PlayingCard.h"
#import "CardMatchingGame.h"
#import <QuartzCore/QuartzCore.h>

@interface CardGameViewController ()
// outlet collection arrays are always strong. While the view will point strongly to the UIButtons 'inside' the array, it will not point to the array itself at all, only the controller will -> the outlet needs to be strongly held in the heap by our controller
// note : remember that an NSArray points strongly to all the elements it contains, and also that each element can be of any kind
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *cardButtons;

@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;

@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *gameModeButton;

@property (weak, nonatomic) IBOutlet UIButton *dealButton;

@property (weak, nonatomic) IBOutlet UISlider *historySlider;

@property (weak, nonatomic) IBOutlet UILabel *historyIndexLabel;

// History function - keep track of all flips so we can replay everything (using a slider)
@property (strong, nonatomic) NSMutableArray* history;

@property (nonatomic) NSUInteger historyIndex;

@property (nonatomic) BOOL timeWarpActive;

// property for our game model
@property (nonatomic, strong) CardMatchingGame *game;

@end

#pragma mark - Custom setters & getters

@implementation CardGameViewController

@synthesize game = _game;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // give the cards a nice background image
    UIImage *cardBackImage = [UIImage imageNamed:@"Butterfly.jpeg"];
    UIImage *noImage = [[UIImage alloc] init];      // simply using 'nil' as parameter for setImage doesn't seem to work!
    
    for(UIButton *cardButton in self.cardButtons)
    {
        // set card background image
        [cardButton setImage:cardBackImage forState:UIControlStateNormal];
        [cardButton setImage:noImage forState:UIControlStateSelected];
        [cardButton setImage:noImage forState:UIControlStateSelected | UIControlStateDisabled];
        [cardButton setImageEdgeInsets:UIEdgeInsetsMake(5,5,5,5)];
    }
}

- (void)setCardButtons:(NSArray *)cardButtons
{    
    // this setter get's called when iOS loads the storyboard!
    
    // it's a setter -> don't forget to set
    _cardButtons = cardButtons;

    [self updateUI];
}

- (CardMatchingGame *)game
{    
    // getter -> lazy instantiation
    if (!_game)
    {
        // game adjusts automatically to the number of buttons on the screen!
        _game = [[CardMatchingGame alloc] initWithCardCount:self.cardButtons.count usingDeck:[[PlayingCardDeck alloc] init]];
    }
    
    return _game;
}

- (void)setGame:(CardMatchingGame *)game
{
    NSLog(@"xxx game setter called xxx");
    _game = game;
    
    [self updateUI];
}

- (NSMutableArray *)history
{
    if (!_history)
    {
        _history = [[NSMutableArray alloc] init];
    }
    return _history;
}

#pragma mark - Helper methods

- (void)updateUI
{
    NSLog(@"-- %@->%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    // updates the user-interface by asking the CardMatchingGame what's going on
    // we just cycle through the card buttons, getting the associated Card from the CardMatchingGame
    
    for (UIButton *cardButton in self.cardButtons)
    {
        // get a Card from the model
        Card *card = [self.game cardAtIndex:[self.cardButtons indexOfObject:cardButton]];
        
        // Set the title in the Selected state to be the Card's contents (if the contents have not changed, this will do nothing)
        [cardButton setTitle:card.contents forState:UIControlStateSelected];
        
        // we set the title when the button is both Selected & Disabled to also be the Card's contents
        // A button shows it's Normal title whenever it is in a state (or combination of states) for which you have not set a title. Our button's Normal title is the Apple logo (the back of the card)
        [cardButton setTitle:card.contents forState:UIControlStateSelected | UIControlStateDisabled];
        
        // select the card only if it isFaceUp
        cardButton.selected = card.isFaceUp;
        
        // make the card untappable if it isUnPlayable
        cardButton.enabled = !card.isUnplayable;
        
        // make disabled buttons semi-transparent
        // Any object in your view can be made transparent simply by setting this alpha @property (1.0 is fully opaque, 0.0 is fully transparant)
        cardButton.alpha = card.isUnplayable ? 0.3 : 1.0;
    }
    
    // update the score
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", self.game.score];
    
    // update the flipsLabel
    self.flipsLabel.text = [NSString stringWithFormat:@"Flips: %d", self.game.flipCount];

    // update the history index label
    self.historyIndexLabel.text = [NSString stringWithFormat:@"%g", self.historySlider.value];
    
    // update the status label
    self.statusLabel.text = self.game.status;
}

#pragma mark - IBAction methods

- (IBAction)flipCard:(UIButton *)sender
{
    NSLog(@"-- %@->%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    // ignore the card buttons when we are timeWarping !!!
    if (self.timeWarpActive)
        return;
    
    // at the very first flip, we need to do some stuff
    if (self.game.flipCount == 0)
    {
        // disable the segmented control
        self.gameModeButton.enabled = NO;
        
        // enable the slider, and show the label
        self.historySlider.enabled = YES;
        self.historyIndexLabel.hidden = NO;
    }
    
    // we won't flip cards ourselves anymore, we'll let the CardMatchingGame do it
    [self.game flipCardAtIndex:[self.cardButtons indexOfObject:sender]];

    // add event to history (also updates the UISlider's number of positions)
    [self addFlipEventToHistory:[self.cardButtons indexOfObject:sender]];
    
    // update the UI when a card gets flipped
    [self updateUI];
}

- (IBAction)startNewGame:(id)sender
{
    // very ellegant way to start a new game is to set self.game to nil -> next time the getter of game is called (happens right after this in updateUI) -> a new pack of cards will be generated
    self.game = nil;

    // (re)enable the segmented control so a new game mode can be selected
    self.gameModeButton.enabled = YES;

    // a new game has been created -> it's convenient for the user that the game mode stays in the last selected mode
    // -> we need to set the game mode again, let's call the segmented control's action method (TBD : is there a better way/place to do this maybe???)
    [self gameModeChanged:self.gameModeButton];
    
    // clear history
    self.history = nil;
    
    // set the slider to the right side, and disable it
    // we need to do a trick here, and set the value to '1', even though it should be '0', but with both min & max value set to 0, the thumb moves to the left, and I prefer to have it on the right (back in time means dragging the slider to the left)
    self.historySlider.maximumValue = 1;
    self.historySlider.value = 1;
    self.historySlider.enabled = NO;
    
    // let's set the history index to 0 but also hidden, because of the above trick
    self.historyIndex = 0;
    self.historyIndexLabel.hidden = TRUE;
    
    // now update the UI - the call to the updateUI will create a new game the first time the getter is called!
    [self updateUI];
}

- (IBAction)gameModeChanged:(UISegmentedControl *)sender
{
    NSLog(@"mode changed %d", sender.selectedSegmentIndex);

    // index 0 == 2 card mode, index 1 == 3 card mode, index 2 == 4 card mode, ...
    self.game.numberOfCardsToMatch = sender.selectedSegmentIndex + 2;
}

#pragma mark - Methods to handle History

- (void)addFlipEventToHistory:(NSUInteger)index
{
    [self.history addObject:[NSNumber numberWithInt:index]];
    
    NSLog(@"events in history : %d", self.history.count);
    
    // each time a flipEvent is added to the history, we must update the sliders's maximum value
    self.historySlider.maximumValue = self.history.count;
    
    // keep the slider positioned at the last event
    self.historySlider.value = self.historySlider.maximumValue;
    
    [self updateUI];
}

- (void)timeWarpToFlipEvent:(NSUInteger)event
{
    NSLog(@"Time warping to flip #%d", event);
    
    // reset to beginning state of this game ('no cards flipped' situation)
    [self.game resetGame];
    
    // now 'replay' each flip event
    for (NSUInteger i = 0; i < event; i++)
    {
        NSUInteger indexOfCard = [(NSNumber *)self.history[i] intValue];
        NSLog(@"\t flip card at index %d", indexOfCard);
        [self.game flipCardAtIndex:indexOfCard];
    }
    
    [self updateUI];
}

- (IBAction)historySliderChanged:(UISlider *)sender
{
    NSLog(@"slider value : %g", sender.value);
    
    // make the UISlider 'stepping' through int values
    NSUInteger value = (NSUInteger)(round(sender.value));
    [sender setValue:value animated:NO];
    
    // detect a start of TimeWarp
    if ((!self.timeWarpActive) && (value != self.history.count))
    {
        // keep track of state
        self.timeWarpActive = YES;
        
        // disable the deal button (card buttons cannot be disabled here, as that is part of the regular functionality)
        self.dealButton.enabled = NO;
        self.dealButton.alpha = 0.3;
        
        // do some cool animation to make clear to the user we're timeWarping
        [UIView animateWithDuration:0.3 animations:^{self.view.backgroundColor = [UIColor darkGrayColor];}];
        
        NSLog(@"Timewarp started");
    }
    
    if (self.timeWarpActive)
    {
        // only update if the slider moved to a different value
        if (self.historyIndex != value)
        {
            self.historyIndex = value;
            
            // if we need to go back in time, disable some stuff
            [self timeWarpToFlipEvent:self.historyIndex];
            
            [self updateUI];
        }
        else
            NSLog(@"same value, nothing to do in timeWarp");
    }
    
    // detect end of TimeWarp
    if (self.timeWarpActive && (value == self.history.count))
    {
        // keep track of the state
        self.timeWarpActive = NO;
        
        // re-enable the deal button
        self.dealButton.enabled = YES;
        self.dealButton.alpha = 1.0;
        
        // animate back to the present
        [UIView animateWithDuration:0.3 animations:^{self.view.backgroundColor = [UIColor whiteColor];}];
        
        NSLog(@"Timewarp ended");
    }
}

@end
