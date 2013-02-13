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

@interface CardGameViewController ()

@property (weak, nonatomic) IBOutlet UILabel *suitLabel;
@property (weak, nonatomic) IBOutlet UILabel *rankLabel;

@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfCardsInDeckLabel;
@property (nonatomic) int flipCount;
@property (nonatomic) int cardsInDeckCount;

@property (nonatomic, strong) Deck *deck;

@end

@implementation CardGameViewController

- (void)viewDidLoad
{
    // update the label
    // note : first tried to use 'awakeFromNib', but at that point the label has not yet been created
    self.cardsInDeckCount = self.deck.numberOfCardsInDeck;
}

- (Deck *)deck
{
    // lazy instantiation
    if (!_deck)
    {
        // note that we alloc/init a PlayingCardDeck, but assign it to a Deck. A PlayingCardDeck 'is a' Deck (but a Deck is not a PlayingCard)
        _deck = [[PlayingCardDeck alloc] init];
    }
    
    return _deck;
}

- (void)setFlipCount:(int)flipCount
{
    // it's a setter, so don't forget to set :-)
    _flipCount = flipCount;
    
    // using the setter to update the flipsLabel
    self.flipsLabel.text = [NSString stringWithFormat:@"Flips: %d", self.flipCount];
    
    NSLog(@"flips updated to %d", self.flipCount);
}

- (void)setCardsInDeckCount:(int)cardsInDeckCount
{
    // it's a setter, so don't forget to set
    _cardsInDeckCount = cardsInDeckCount;
    
    // use the setter to update the label
    self.numberOfCardsInDeckLabel.text = [NSString stringWithFormat:@"Cards in deck: %d", self.cardsInDeckCount];
}

- (IBAction)flipCard:(UIButton *)sender
{
    // toggle button state between 'default' & 'selected'
    // 'default' shows the back of the card
    // 'selected' shows the suit & rank
    
    // HW0 : make each flip draw a new card
    
    // alt-click on 'selected' -> you'll see that the getter for this BOOL is called 'isSelected'
    if (!sender.isSelected)
    {
        // get a new random card and update it's title (in the 'selected' state)
        Card *card = [self.deck drawRandomCard];
        [sender setTitle:card.contents forState:UIControlStateSelected];
        
        // update nbr of cards in deck -> should better be performed by drawRandomCard, so we don't forget this -> use @protocols?
        self.cardsInDeckCount = self.deck.numberOfCardsInDeck;
        
        // show the suit & rank of the PlayingCard (if it is a PlayingCard)
        if ([card isKindOfClass:[PlayingCard class]])
        {
            self.suitLabel.text = [NSString stringWithFormat:@"Suit: %@", [(PlayingCard *)card suit]];
            self.rankLabel.text = [NSString stringWithFormat:@"Rank: %d",[(PlayingCard *)card rank]];
        }
    }
    
    // toggle button state
    sender.selected = !sender.isSelected;
    
    // increment the count each time we flip
    self.flipCount++;
}


@end
