import 'dart:math';

class Utils
{
  //static String pathImages = "soft_";
  static String pathImages = "";

  static void log(String message)
  {
    print(message);
  }

  static String generateUUID() 
  {
    Random random = new Random();

    final String hexDigits = "0123456789abcdef";
    final List<String> uuid = [];

    for (int i = 0; i < 36; i++) 
    {
      final int hexPos = random.nextInt(16);
      final String substring = hexDigits.substring(hexPos, hexPos + 1);
      uuid.add(substring);
    }

    int pos = (int.parse(uuid[19], radix: 16) & 0x3) | 0x8; // bits 6-7 of the clock_seq_hi_and_reserved to 01

    uuid[14] = "4";  // bits 12-15 of the time_hi_and_version field to 0010
    uuid[19] = hexDigits.substring(pos, pos + 1);

    uuid[8] = uuid[13] = uuid[18] = uuid[23] = "-";

    final StringBuffer buffer = new StringBuffer();
    buffer.writeAll(uuid);
    return buffer.toString();
  }

  static logRun(String message)
  {
    //print(message);
  }

  static int countBuild = 1;
  static logBuild(String message)
  {
    //print(countBuild.toString() + " : " + message);
    countBuild++;
  }

  static logFromJson(String message)
  {
    //print(message);
  }

  static logToMap(String message)
  {
    //print(message);
  }
}