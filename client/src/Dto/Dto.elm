module Dto.Dto exposing (..)


type alias AddressId =
    { address : String
    , id : String
    }

type alias PropertyData =
    { address : String
    , baths : Maybe Int
    , bedrooms : Maybe Int
    , carParks : Maybe Int
    , estimate : Maybe Int
    , estimateDate : Maybe Int
    , estimateSaleDiff : Maybe Float
    , floorArea : Maybe Int
    , landArea : Maybe Int
    , rateableValue : Maybe Int
    , rateableValueDate : Maybe Int
    , estimateRvDiff : Maybe Float
    , rvSaleDiff : Maybe Float
    , salePrice : Maybe Int
    , saleDate : Maybe Int
    }