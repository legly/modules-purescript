module Test.Main where

import Prelude (Unit, discard)
import Effect (Effect)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (run)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)

import Test.Checker as Checker
import Test.Period as Period
import Test.NamedNumber as NamedNumber
import Test.Calculator as Calculator
import Test.Utility as Utility

import Main (UnparsedConfig, Response, setup)
import Period (Period)
import Data.Nullable (toNullable)
import Data.Maybe (Maybe(Just))

foreign import config :: UnparsedConfig
foreign import catchSetupError :: (UnparsedConfig -> (String -> Response)) -> UnparsedConfig -> String
foreign import catchTimeError :: (String -> Response) -> String -> String
foreign import dodgyPeriod :: Period

-- tests
main :: Effect Unit
main = run [consoleReporter] do
    Calculator.checks
    Checker.checks
    NamedNumber.checks
    Period.checks
    Utility.checks

    describe "Main (setup)" do
        it "parses config" do
            setup config "uekdjeis1" `shouldEqual` {
                level: toNullable (Just "warning"),
                time: "42 minutes",
                checks: [
                    {
                        level: "warning",
                        message: "Your password looks like it might just be a word and a few digits. This is a very common pattern and would be cracked very quickly.",
                        name: "Possibly a Word and a Number"
                    },
                    {
                        level: "warning",
                        message: "Your password is quite short. The longer a password is the more secure it will be.",
                        name: "Length: Short"
                    },
                    {
                        level: "notice",
                        message: "Your password only contains numbers and letters. Adding a symbol can make your password more secure. Don't forget you can often use spaces in passwords.",
                        name: "Character Variety: No Symbols"
                    }
                ]
            }

        it "shows instant for insecure passwords" do
            setup config "password1" `shouldEqual` {
                level: toNullable (Just "insecure"),
                time: "instantly",
                checks: [
                    {
                        level: "insecure",
                        message: "Your password is very commonly used. It would be cracked almost instantly.",
                        name: "Common Password: In the top 621 most used passwords"
                    },
                    {
                        level: "warning",
                        message: "Your password looks like it might just be a word and a few digits. This is a very common pattern and would be cracked very quickly.",
                        name: "Possibly a Word and a Number"
                    },
                    {
                        level: "warning",
                        message: "Your password is quite short. The longer a password is the more secure it will be.",
                        name: "Length: Short"
                    },
                    {
                        level: "notice",
                        message: "Your password only contains numbers and letters. Adding a symbol can make your password more secure. Don't forget you can often use spaces in passwords.",
                        name: "Character Variety: No Symbols"
                    }
                ]
            }

        it "shows forever for secure passwords" do
            setup {
                calcs: config.calcs,
                periods: [{
                    singular: "blahtosecond",
                    plural: "blahtoseconds",
                    seconds: 0.1
                }],
                namedNumbers: config.namedNumbers,
                characterSets: config.characterSets,
                dictionary: config.dictionary,
                patterns: config.patterns,
                checkMessages: config.checkMessages
            } "aVeryLong47&83**AndComplicated(8347)PasswordThatN0OneCouldEverGuess" `shouldEqual` {
                level: toNullable (Just "achievement"),
                time: "forever",
                checks: [{
                    level: "achievement",
                    message: "Your password is over sixteen characters long.",
                    name: "Length: Long"
                }]
            }


        it "throws parsing errors" do
           catchSetupError setup {
               calcs: config.calcs,
               periods: [],
               namedNumbers: config.namedNumbers,
               characterSets: config.characterSets,
               dictionary: config.dictionary,
               patterns: config.patterns,
               checkMessages: config.checkMessages
           } `shouldEqual` "Invalid periods dictionary"

           catchSetupError setup {
               calcs: config.calcs,
               periods: config.periods,
               namedNumbers: [],
               characterSets: config.characterSets,
               dictionary: config.dictionary,
               patterns: config.patterns,
               checkMessages: config.checkMessages
           } `shouldEqual` "Invalid named numbers dictionary"

           catchSetupError setup {
               calcs: config.calcs,
               periods: config.periods,
               namedNumbers: config.namedNumbers,
               characterSets: [],
               dictionary: config.dictionary,
               patterns: config.patterns,
               checkMessages: config.checkMessages
           } `shouldEqual` "Invalid character sets dictionary"

           catchSetupError setup {
               calcs: config.calcs,
               periods: config.periods,
               namedNumbers: config.namedNumbers,
               characterSets: config.characterSets,
               dictionary: [],
               patterns: config.patterns,
               checkMessages: config.checkMessages
           } `shouldEqual` "Invalid password dictionary"

           catchSetupError setup {
               calcs: config.calcs,
               periods: config.periods,
               namedNumbers: config.namedNumbers,
               characterSets: config.characterSets,
               dictionary: config.dictionary,
               patterns: [],
               checkMessages: config.checkMessages
           } `shouldEqual` "Invalid patterns dictionary"
