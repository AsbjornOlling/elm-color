module ColorTest exposing (all)

import Color exposing (Color)
import Expect exposing (FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer, bool, floatRange, intRange)
import Hex
import Test exposing (..)



--
-- Fuzzers
--


unit : Fuzzer Float
unit =
    floatRange 0 1


int255 : Fuzzer Int
int255 =
    intRange 0 255


tuple2 : Fuzzer a -> Fuzzer b -> Fuzzer ( a, b )
tuple2 a b =
    Fuzz.tuple ( a, b )


tuple3 : Fuzzer a -> Fuzzer b -> Fuzzer c -> Fuzzer ( a, b, c )
tuple3 a b c =
    Fuzz.tuple3 ( a, b, c )


hex : Fuzzer Char
hex =
    Fuzz.oneOf (List.map Fuzz.constant <| String.toList "0123456789abcdefABCDEF")


hex2 : Fuzzer String
hex2 =
    Fuzz.map2 (\a b -> String.fromList [ a, b ]) hex hex



--
-- Tests
--


all : Test
all =
    describe "Color"
        [ test "defines a Color type" <|
            \() ->
                let
                    color : Color
                    color =
                        Color.rgba 0 0 0 0
                in
                color
                    |> Expect.equal color
        , fuzz (tuple2 (tuple3 unit unit unit) unit)
            "can represent RGBA colors (fromRgba)"
          <|
            \( ( r, g, b ), a ) ->
                Color.fromRgba { red = r, green = g, blue = b, alpha = a }
                    |> Color.toRgba
                    |> Expect.all
                        [ .red >> Expect.within (Absolute 0.000001) r
                        , .green >> Expect.within (Absolute 0.000001) g
                        , .blue >> Expect.within (Absolute 0.000001) b
                        , .alpha >> Expect.within (Absolute 0.000001) a
                        ]
        , fuzz (tuple2 (tuple3 unit unit unit) unit)
            "can represent RGBA colors (rgba)"
          <|
            \( ( r, g, b ), a ) ->
                Color.rgba r g b a
                    |> Color.toRgba
                    |> Expect.all
                        [ .red >> Expect.within (Absolute 0.000001) r
                        , .green >> Expect.within (Absolute 0.000001) g
                        , .blue >> Expect.within (Absolute 0.000001) b
                        , .alpha >> Expect.within (Absolute 0.000001) a
                        ]
        , fuzz (tuple3 unit unit unit)
            "can represent RGBA colors (rgb)"
          <|
            \( r, g, b ) ->
                Color.rgb r g b
                    |> Color.toRgba
                    |> Expect.all
                        [ .red >> Expect.within (Absolute 0.000001) r
                        , .green >> Expect.within (Absolute 0.000001) g
                        , .blue >> Expect.within (Absolute 0.000001) b
                        , .alpha >> Expect.equal 1.0
                        ]
        , fuzz (tuple3 int255 int255 int255)
            "can represent RGB255 colors"
          <|
            \( r, g, b ) ->
                Color.rgb255 r g b
                    |> Color.toRgba
                    |> Expect.all
                        [ .red >> Expect.within (Absolute 0.000001) (toFloat r / 255)
                        , .green >> Expect.within (Absolute 0.000001) (toFloat g / 255)
                        , .blue >> Expect.within (Absolute 0.000001) (toFloat b / 255)
                        , .alpha >> Expect.equal 1.0
                        ]
        , describe "can convert from hex strings" <|
            let
                hashPrefix bool string =
                    if bool then
                        "#" ++ string

                    else
                        string

                hex2ToUnit string =
                    Hex.fromString (String.toLower string) |> Result.map (\x -> toFloat x / 255)
            in
            [ fuzz (tuple2 bool (tuple3 hex2 hex2 hex2))
                "6-digit string"
              <|
                \( withHash, ( r, g, b ) ) ->
                    String.concat [ r, g, b ]
                        |> hashPrefix withHash
                        |> Color.fromHex
                        |> Color.toRgba
                        |> Expect.all
                            [ .red >> Ok >> Expect.equal (hex2ToUnit r)
                            , .green >> Ok >> Expect.equal (hex2ToUnit g)
                            , .blue >> Ok >> Expect.equal (hex2ToUnit b)
                            , .alpha >> Expect.equal 1.0
                            ]
            , fuzz (tuple2 bool (tuple3 hex hex hex))
                "3-digit string"
              <|
                \( withHash, ( r, g, b ) ) ->
                    String.fromList [ r, g, b ]
                        |> hashPrefix withHash
                        |> Color.fromHex
                        |> Color.toRgba
                        |> Expect.all
                            [ .red >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ r, r ])
                            , .green >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ g, g ])
                            , .blue >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ b, b ])
                            , .alpha >> Expect.equal 1.0
                            ]
            , fuzz (tuple3 bool (tuple3 hex2 hex2 hex2) hex2)
                "8-digit string"
              <|
                \( withHash, ( r, g, b ), a ) ->
                    String.concat [ r, g, b, a ]
                        |> hashPrefix withHash
                        |> Color.fromHex
                        |> Color.toRgba
                        |> Expect.all
                            [ .red >> Ok >> Expect.equal (hex2ToUnit r)
                            , .green >> Ok >> Expect.equal (hex2ToUnit g)
                            , .blue >> Ok >> Expect.equal (hex2ToUnit b)
                            , .alpha >> Ok >> Expect.equal (hex2ToUnit a)
                            ]
            , fuzz (tuple3 bool (tuple3 hex hex hex) hex)
                "4-digit string"
              <|
                \( withHash, ( r, g, b ), a ) ->
                    String.fromList [ r, g, b, a ]
                        |> hashPrefix withHash
                        |> Color.fromHex
                        |> Color.toRgba
                        |> Expect.all
                            [ .red >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ r, r ])
                            , .green >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ g, g ])
                            , .blue >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ b, b ])
                            , .alpha >> Ok >> Expect.equal (hex2ToUnit <| String.fromList [ a, a ])
                            ]
            ]
        , fuzz (tuple2 (tuple3 int255 int255 int255) unit)
            "can convert to hex strings"
          <|
            \( ( r, g, b ), a ) ->
                Color.rgba (toFloat r / 255) (toFloat g / 255) (toFloat b / 255) a
                    |> Color.toHex
                    |> Expect.all
                        [ .hex
                            >> Expect.equal
                                (String.concat
                                    [ "#"
                                    , String.pad 2 '0' (Hex.toString r)
                                    , String.pad 2 '0' (Hex.toString g)
                                    , String.pad 2 '0' (Hex.toString b)
                                    ]
                                )
                        , .alpha >> Expect.within (Absolute 0.000001) a
                        ]
        ]
