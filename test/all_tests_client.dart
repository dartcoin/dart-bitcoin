library dartcoin.test.all_client;

import "package:unittest/html_enhanced_config.dart";

import "./all_tests.dart" as all_tests;

void main() {

  useHtmlEnhancedConfiguration();
  
  all_tests.main();

}