pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

--https://www.thonky.com/qr-code-tutorial

printEC=false

tweet_url=
"https://twitter.com/intent/tweettexti%20just%20played%20this%20great%20%23pico8%20game%0come%20check%20it%20out%3A%0Ahttps%3A%2F%2Fwww.lexaloffle.com%2Fbbs%2F%3Ftid%3D31506"
--"https://twitter.com/intent/tweet?text=I%20just%20played%20this%20great%20%23Pico8%20game!%0ACome%20check%20it%20out%3A%0Ahttps%3A%2F%2Fwww.lexaloffle.com%2Fbbs%2F%3Ftid%3D31506&=&=undefined&"
-------------------------------helpers------------------------------------------

function integerToBinary(binaryValue,totalBits)
  --Source https://www.lexaloffle.com/bbs/?tid=27657
  local result,a="",0
  for i = 0,totalBits-1 do
   result=band(2^i,binaryValue)/2^i..result
  end
  return result
end

function getAlphanumericCharacterValue(character)
 if (character=="") return 0
 local values="0123456789abcdefghijklmnopqrstuvwxyz $%*+-./:"
 local result=1
 while character != sub(values,result,result) do
  result+=1
 end
 return result-1
end

 --------------------------QR code functions------------------------------------

function makeQRCode(dataToEncode)
 --lets use alphanumeric encoding since we're working with URLS
 --    WRONG DUMMY, can't have ? or caps which rules out youtube URLs for a start

 --let's also go with the L error correction level (15% of data can be lost and still readable)
 local dataSize = #dataToEncode * 1.07
 local version = findMinimumQrCodeVersionRequiredForLLevelErrorCorrectionOfAlphanumericData(dataSize)

 local encodedData = encodeDataAsBinaryString(dataToEncode, version)
 local errorCorrectionCodewords = generateErrorCorrectionCodeWords(version, encodedData)

  --for larg message, data interweaving data her (yuck, sounds hard!)

  --Now it's time for MODULE PLAEMENT IN  MATRIX!
  --place finder patterns
  cls(6)
  version=8
  local cornerPosition=(((version-1)*4)+21) - 7
  rectfill(0,0,cornerPosition+6,cornerPosition+6,3)
  reserveFormatInformationArea(cornerPosition)
  placeTimingPatterns(cornerPosition)
  placeFinderPattern(0,0,0,7)
  placeFinderPattern(cornerPosition,0,0,7)
  placeFinderPattern(0,cornerPosition,0,7)
  placeSeperators(cornerPosition,7)

  if version>2 then
    --Add alignment patterns
    local placementArray=getAlignmentPatternLocations(version)
    for x=6,placementArray[#placementArray],placementArray[2]-placementArray[1] do
     for y=6,placementArray[#placementArray],placementArray[2]-placementArray[1] do
       if not((x==6 and y==6) or
             (x==6 and y==placementArray[#placementArray]) or
             (y==6 and x==placementArray[#placementArray])) then
        placeAlignmentPattern(x,y,0,7)
      end
     end
    end
  end
  placeDarkModule(version)
  reserveVersionInformationArea(cornerPosition)
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
  ?""
end

 ---------------------------Module placement matrix-----------------------------

function placeTimingPatterns(cornerPosition)
  fillp(0xa5a5)
  line(6,0,6,cornerPosition,7)
  line(0,6,cornerPosition,6,7)
  fillp()
end

function placeFinderPattern(x,y,c1,c2)
  rectfill(x,y,x+6,y+6,c1)
  rectfill(x+1,y+1,x+5,y+5,c2)
  rectfill(x+2,y+2,x+4,y+4,c1)
end

function placeSeperators(cornerPosition,c)
  line(0,7,7,7,c)
  line(7,0,7,7,c)
  line(cornerPosition-1,7,cornerPosition+6,7,c)
  line(cornerPosition-1,0,cornerPosition-1,7,c)
  line(7,cornerPosition-1,7,cornerPosition+6,c)
  line(0,cornerPosition-1,7,cornerPosition-1,c)
end

function placeAlignmentPattern(x,y,c1,c2)
  rect(x-2,y-2,x+2,y+2,c1)
  rect(x-1,y-1,x+1,y+1,c2)
  pset(x,y,c1)
end

function getAlignmentPatternLocations(version)
   return ({
      {6,18},
      {6,22},
      {6,26},
      {6,30},
      {6,34},
      {6,22,38},
      {6,24,42},
      {6,26,46}
   })[version-1]
end

function placeDarkModule(version)
  pset(8,(4*version) + 9,0)
end

function reserveFormatInformationArea(cornerPosition)
  line(0,8,8,8,12)
  line(8,0,8,8,12)
  line(8,cornerPosition-1,8,cornerPosition+6,12)
  line(cornerPosition-1,8,cornerPosition+6,8,12)
end

function reserveVersionInformationArea(cornerPosition)
  rectfill(0,cornerPosition-2,5,cornerPosition-4,11)
  rectfill(cornerPosition-2,0,cornerPosition-4,5,11)
end
------------------------------Data encoding-------------------------------------

function encodeDataAsBinaryString(dataToEncode, version)
 local modeIndicator = "0010"
 local originalInputLengthInBinary = integerToBinary(#dataToEncode,9)
 local encodedData = modeIndicator..originalInputLengthInBinary..encodeAlphaNumericStringToBinary(dataToEncode)

 local requiredDataLength = findTotalNumberOfDataCodewordsForVersion(version)*8
 local paddingRequired = requiredDataLength - #encodedData
 if paddingRequired>15 then
  encodedData=encodedData.."0000"
 else
  encodedData=encodedData..integerToBinary(paddingRequired)
 end

 local additionalPaddingRequiredToMakeEncodedDataLengthAMultipleOf8=#encodedData%8
 if additionalPaddingRequiredToMakeEncodedDataLengthAMultipleOf8!=0 then
  for i=0,7-additionalPaddingRequiredToMakeEncodedDataLengthAMultipleOf8 do
   encodedData=encodedData.."0"
  end
 end

 local bool236or17=true
 while #encodedData < requiredDataLength do
  if (bool236or17) encodedData=encodedData.."11101100"--236
  if (not bool236or17) encodedData=encodedData.."00010001"--17
  bool236or17=not bool236or17
 end

 return encodedData
end

function findMinimumQrCodeVersionRequiredForLLevelErrorCorrectionOfAlphanumericData(dataSize)
 --values here going from version 1 to 9
 local upperLimits={25,47,77,114,154,195,224,279,335}
 local optimalVersion=1

 if dataSize > upperLimits[#upperLimits] then
  ?"data is too big!"
  return
 end

 while dataSize > upperLimits[optimalVersion]do
  optimalVersion+=1
 end
 return optimalVersion
end

--For L Error Correction level
function findTotalNumberOfDataCodewordsForVersion(version)
 local valuesForMediumErrorCorrection={19,34,55,80,108,136,156,194,232}
 return valuesForMediumErrorCorrection[version]
end

function encodeAlphaNumericStringToBinary(dataToEncode)
 local encodedData=""
 for i=1,#dataToEncode,2 do
  local firstCharacterToBeEncoded = sub(dataToEncode,i,i)
  local secondCharacterToBeEncoded = sub(dataToEncode,i+1,i+1)
  if (secondCharacterToBeEncoded=="") then
   --encode final character as 6 bit binary string
   encodedData=encodedData..integerToBinary(getAlphanumericCharacterValue(firstCharacterToBeEncoded),6)
  else
   local twoCharactersToBeConvertedToBinary=
          getAlphanumericCharacterValue(firstCharacterToBeEncoded)*45
          + getAlphanumericCharacterValue(secondCharacterToBeEncoded)
   encodedData=encodedData..integerToBinary(twoCharactersToBeConvertedToBinary,11)
  end
 end
 return encodedData
end

 --------------------------Error correction-------------------------------------

function generateErrorCorrectionCodeWords(version, encodedData)
  local messagePolynomial={}
  for i=1,#encodedData,8 do
   add(messagePolynomial,tonum("0b"..sub(encodedData,i,i+7)))
  end
  --instead of generating the error correction polynomials
  -- we'll instead fetch the results from a list since maths is hard and life's too short
  originalErrorCorrectionPolynomial = getPreGeneratedPolynomialForErrorCorrectionLevelLForVersion(version)

  --hello world 1-m testing
  --originalErrorCorrectionPolynomial={0 ,251,67,46 ,61 ,118,70 ,64,94,32,45}
  --messagePolynomial={32,91 ,11,120,209,114,220,77,67,64,236,17,236,17,236,17}

  errorCorrectionPolynomial={}
  for a in all(originalErrorCorrectionPolynomial) do
    add(errorCorrectionPolynomial,a)
  end

  local errorCorrectionCodeWordsForGroup1={7,10,15,20,26,18,20,24,30}
  local numberOfBlocksRequiredInGroup1={1,1,1,1,1,2,2,2,2}
  local totalDivisionStepsRequired=#messagePolynomial

  --make sure lead term for each polynomial exponent is the same
  for i=2,#messagePolynomial do
    add(errorCorrectionPolynomial,0)
  end
  --for i=1,errorCorrectionCodeWordsForGroup1[version] do
  for i=1,errorCorrectionCodeWordsForGroup1[version]+3 do
    add(messagePolynomial,0)
  end
 local useMeforDivision=messagePolynomial
 for j=1,totalDivisionStepsRequired do
  for i=1,#errorCorrectionPolynomial do
    if i<#originalErrorCorrectionPolynomial+1 then
      errorCorrectionPolynomial[i]=(getAlphaNotationValueForDecimal(useMeforDivision[1])+originalErrorCorrectionPolynomial[i])%255
      errorCorrectionPolynomial[i]=bxor(getDecimalValueForAlphaNotation(errorCorrectionPolynomial[i]),useMeforDivision[i])
    else
      errorCorrectionPolynomial[i]=bxor(0,useMeforDivision[i])
    end
  end
  useMeforDivision={}
  while (errorCorrectionPolynomial[1]==0) do
    del(errorCorrectionPolynomial,errorCorrectionPolynomial[1])
  end
  for a in all(errorCorrectionPolynomial) do
    add(useMeforDivision,a)
  end
 end
 if printEC then
   ?#errorCorrectionPolynomial
   for i=1,#errorCorrectionPolynomial do
     ?#errorCorrectionPolynomial-i..": "..errorCorrectionPolynomial[i]
   end
   stop()
 end
 return errorCorrectionPolynomial
end

function getPreGeneratedPolynomialForErrorCorrectionLevelLForVersion(version)
 --get codewords required for group 1
 local preGeneratedPolynomialForErrorCorrectionLevelL={
  {0,87,229,146,149,238,102,21},
  {0,251,67,46,61,118,70,64,94,32,45},
  {0,8,183,61,91,202,37,51,58,58,237,140,124,5,99,105}
 }
 return preGeneratedPolynomialForErrorCorrectionLevelL[version]
end

function getAlphaNotationValueForDecimal(value)
  --Pico 8 has no log() function, nor does it handle large numbers well
  -- therefore a horrid lookup table is best scenario here
  return ({0,1,25,2,50,26,198,3,223,51,238,27,104,199,75,4,100,224,14,52,141,239,129,28,193,105,248,200,8,76,113,5,138,101,47,225,36,15,33,53,147,142,218,240,18,130,69,29,181,194,125,106,39,249,185,201,154,9,120,77,228,114,166,6,191,139,98,102,221,48,253,226,152,37,179,16,145,34,136,54,208,148,206,143,150,219,189,241,210,19,92,131,56,70,64,30,66,182,163,195,72,126,110,107,58,40,84,250,133,186,61,202,94,155,159,10,21,121,43,78,212,229,172,115,243,167,87,7,112,192,247,140,128,99,13,103,74,222,237,49,197,254,24,227,165,153,119,38,184,180,124,17,68,146,217,35,32,137,46,55,63,209,91,149,188,207,205,144,135,151,178,220,252,190,97,242,86,211,171,20,42,93,158,132,60,57,83,71,109,65,162,31,45,67,216,183,123,164,118,196,23,73,236,127,12,111,246,108,161,59,82,41,157,85,170,251,96,134,177,187,204,62,90,203,89,95,176,156,169,160,81,11,245,22,235,122,117,44,215,79,174,213,233,230,231,173,232,116,214,244,234,168,80,88,175})[value]
end

function getDecimalValueForAlphaNotation(alphaNotationExponent)
  return ({1,2,4,8,16,32,64,128,29,58,116,232,205,135,19,38,76,152,45,90,180,117,234,201,143,3,6,12,24,48,96,192,157,39,78,156,37,74,148,53,106,212,181,119,238,193,159,35,70,140,5,10,20,40,80,160,93,186,105,210,185,111,222,161,95,190,97,194,153,47,94,188,101,202,137,15,30,60,120,240,253,231,211,187,107,214,177,127,254,225,223,163,91,182,113,226,217,175,67,134,17,34,68,136,13,26,52,104,208,189,103,206,129,31,62,124,248,237,199,147,59,118,236,197,151,51,102,204,133,23,46,92,184,109,218,169,79,158,33,66,132,21,42,84,168,77,154,41,82,164,85,170,73,146,57,114,228,213,183,115,230,209,191,99,198,145,63,126,252,229,215,179,123,246,241,255,227,219,171,75,150,49,98,196,149,55,110,220,165,87,174,65,130,25,50,100,200,141,7,14,28,56,112,224,221,167,83,166,81,162,89,178,121,242,249,239,195,155,43,86,172,69,138,9,18,36,72,144,61,122,244,245,247,243,251,235,203,139,11,22,44,88,176,125,250,233,207,131,27,54,108,216,173,71,142,1})[alphaNotationExponent+1]
end

--makeQRCode(tweet_url)
--makeQRCode("hello world") --make sure to chnage polynomials when testing this!
makeQRCode("craigtinney.co.uk")
--makeQRCode("http://craigtinney.co.uk/carts/games/helicopter.html")
