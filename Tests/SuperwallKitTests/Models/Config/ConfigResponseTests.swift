import XCTest
@testable import SuperwallKit
import CoreMedia

// swiftlint:disable all

let response = #"""
{
  "toggles": [
  {
    "key": "enable_session_events",
    "enabled": true
  },
  {
    "key": "some_unknown_key",
    "enabled": true
  }
  ],
  "build_id": "poWduJZYQvCA8QbWLrjJC",
  "attribution_options":{"apple_search_ads":{"enabled":true}},
  "ts": 1719479293597,
  "trigger_options": [{
    "trigger_version": "V2",
    "event_name": "MyEvent",
    "rules": [{
      "experiment_group_id": "39",
      "experiment_id": "80",
      "expression": null,
      "expression_js": null,
      "preload": {
        "behavior": "ALWAYS",
        "requires_re_evaluation": true
      },
      "variants": [{
        "percentage": 0,
        "variant_type": "HOLDOUT",
        "variant_id": "218"
      }, {
        "percentage": 100,
        "variant_type": "TREATMENT",
        "variant_id": "219",
        "paywall_identifier": "example-paywall-4de1-2022-03-15"
      }]
    }]
  }, {
    "trigger_version": "V2",
    "event_name": "$present",
    "rules": [{
      "experiment_group_id": "38",
      "experiment_id": "66",
      "expression": null,
      "expression_js": null,
      "preload": {
        "behavior": "ALWAYS",
        "requires_re_evaluation": true
      },
      "variants": [{
        "percentage": 0,
        "variant_type": "HOLDOUT",
        "variant_id": "189"
      }, {
        "percentage": 100,
        "variant_type": "TREATMENT",
        "variant_id": "2155",
        "paywall_identifier": "example-paywall-4de1-2022-03-15"
      }]
    }]
  }],
  "product_identifier_groups": [
    ["sk.superwall.annual.89.99_7"]
  ],
  "paywalls": [{
    "products": [{
      "identifier": "sk.superwall.annual.89.99_7"
    }],
    "event_name": "MyEvent",
    "identifier": "example-paywall-4de1-2022-03-15"
  }],
  "paywall_responses": [{
    "local_notifications": [{
      "notification_type": "SOMETHING",
      "title": "test",
      "body": "body",
      "delay": 5000
    },
    {
      "notification_type": "TRIAL_STARTED",
      "title": "test",
      "body": "body",
      "delay": 5000
    }],
    "id": "571",
    "cache_key": "abc?sw=10293",
    "build_id": "abc?sw=10293",
    "url": "https://www.fitnessai.com/superwall-video?sw_cache_key=1659989801716",
    "url_config": {
      "endpoints": [{
        "url": "https://www.fitnessai.com/superwall-video?sw_cache_key=1659989801716",
        "timeout_ms": 1000,
        "percentage": 100
      }],
      "max_attempts": 10
    },
    "name": "Example Paywall",
    "identifier": "example-paywall-4de1-2022-03-15",
    "slug": "example-paywall-4de1-2022-03-15",
    "paywalljs_event": "W3siZXZlbnRfbmFtZSI6InRlbXBsYXRlX3N1YnN0aXR1dGlvbnMiLCJzdWJzdGl0dXRpb25zIjpbeyJrZXkiOiJUaXRsZSIsInZhbHVlIjoiVGVzdCJ9LHsia2V5IjoiVGltZWxpbmUgUm93IDEgVGl0bGUiLCJ2YWx1ZSI6IlRvZGF5IiwiZnJlZVRyaWFsVmFsdWUiOiJUb2RheSJ9LHsia2V5IjoiVGltZWxpbmUgUm93IDEgU3VidGl0bGUiLCJ2YWx1ZSI6IkdldCBmdWxsIGFjY2VzcyB0byBhbGwgb3VyIGZlYXR1cmVzIn0seyJrZXkiOiJUaW1lbGluZSBSb3cgMiBUaXRsZSIsInZhbHVlIjoiSW4gNSBEYXlzIn0seyJrZXkiOiJUaW1lbGluZSBSb3cgMiBTdWJ0aXRsZSIsInZhbHVlIjoiR2V0IGEgcmVtaW5kZXIgYWJvdXQgd2hlbiB5b3VyIGZyZWUgdHJpYWwgZW5kcyJ9LHsia2V5IjoiVGltZWxpbmUgUm93IDMgVGl0bGUiLCJ2YWx1ZSI6IkluIDcgRGF5cyJ9LHsia2V5IjoiVGltZWxpbmUgUm93IDMgU3VidGl0bGUiLCJ2YWx1ZSI6IkdldCBiaWxsZWQsIHVubGVzcyB5b3UgY2FuY2VsIGFueXRpbWUgYmVmb3JlIn0seyJrZXkiOiJSZXN0b3JlIExhYmVsIiwidmFsdWUiOiJBbHJlYWR5IHN1YnNjcmliZWQ/In0seyJrZXkiOiJQcmltYXJ5IFByb2R1Y3QgU3RyaWtlIFRocm91Z2giLCJ2YWx1ZSI6IiQwLjAwIn0seyJrZXkiOiJQcmltYXJ5IFByb2R1Y3QgTGluZSAxIiwidmFsdWUiOiIkMC4wMCBwZXIgcGVyaW9kIn0seyJrZXkiOiJQcmltYXJ5IFByb2R1Y3QgTGluZSAyIiwidmFsdWUiOiIwLWRheSBmcmVlIHRyaWFsIn0seyJrZXkiOiJQcmltYXJ5IFByb2R1Y3QgQmFkZ2UiLCJ2YWx1ZSI6IkJlc3QgVmFsdWUifSx7ImtleSI6IlNlY29uZGFyeSBQcm9kdWN0IExpbmUgMSIsInZhbHVlIjoiJDAuMDAgcGVyIHBlcmlvZCJ9LHsia2V5IjoiU2Vjb25kYXJ5IFByb2R1Y3QgTGluZSAyIiwidmFsdWUiOiIwLWRheSBmcmVlIHRyaWFsIn0seyJrZXkiOiJUZXJ0aWFyeSBQcm9kdWN0IExpbmUgMSIsInZhbHVlIjoiJDAuMDAgcGVyIHBlcmlvZCJ9LHsia2V5IjoiVGVydGlhcnkgUHJvZHVjdCBMaW5lIDIiLCJ2YWx1ZSI6IjAtZGF5IGZyZWUgdHJpYWwifSx7ImtleSI6IlByaW1hcnkgQ1RBIFN1YnRpdGxlIiwidmFsdWUiOiIkMC4wMC95ciBBZnRlciBZb3VyIEZyZWUgVHJpYWwifSx7ImtleSI6IlNlY29uZGFyeSBDVEEgU3VidGl0bGUiLCJ2YWx1ZSI6IiQwLjAwL3lyIEFmdGVyIFlvdXIgRnJlZSBUcmlhbCJ9LHsia2V5IjoiVGVydGlhcnkgQ1RBIFN1YnRpdGxlIiwidmFsdWUiOiIkMC4wMC95ciBBZnRlciBZb3VyIEZyZWUgVHJpYWwifSx7ImtleSI6Ik90aGVyIFBsYW5zIEJ1dHRvbiIsInZhbHVlIjoiT3RoZXIgUGxhbnMifSx7ImtleSI6IlB1cmNoYXNlIFByaW1hcnkiLCJ2YWx1ZSI6IkNvbnRpbnVlIn0seyJrZXkiOiJQdXJjaGFzZSBTZWNvbmRhcnkiLCJ2YWx1ZSI6IkNvbnRpbnVlIn0seyJrZXkiOiJQdXJjaGFzZSBUZXJ0aWFyeSIsInZhbHVlIjoiQ29udGludWUifSx7ImtleSI6InB1cmNoYXNlLXByaW1hcnkiLCJ2YWx1ZSI6IkNvbnRpbnVlIn0seyJrZXkiOiJwdXJjaGFzZS1zZWNvbmRhcnkiLCJ2YWx1ZSI6IkNvbnRpbnVlIn0seyJrZXkiOiJwdXJjaGFzZS10ZXJ0aWFyeSIsInZhbHVlIjoiQ29udGludWUifSx7ImtleSI6InRpdGxlIiwidmFsdWUiOiJ7e3ByaW1hcnkudHJpYWxQZXJpb2REYXlzfX0gZGF5cyBGUkVFIHRoZW4ge3twcmltYXJ5LmRhaWx5UHJpY2V9fS9kYXkgYmlsbGVkIGV2ZXJ5IHt7cHJpbWFyeS5wZXJpb2R9fSJ9LHsia2V5Ijoic3VidGl0bGUiLCJ2YWx1ZSI6IkhleSAge3sgdXNlci5maXJzdE5hbWUgfX0hXG5Pbmx5ICQxLjczIHBlciB3ZWVrIGJpbGxlZCBhbm51YWxseS4gVGhhdCdzIDUwLTEwMHggY2hlYXBlciB0aGFuIGEgdHJhaW5lci48YnI+In0seyJrZXkiOiJidWxsZXQtMSIsInZhbHVlIjoiT3B0aW1pemVkIHdvcmtvdXRzIGV2ZXJ5ZGF5PGJyPiJ9LHsia2V5IjoiYnVsbGV0LTIiLCJ2YWx1ZSI6IkFkYXB0ZWQgdG8geW91ciBzdHJlbmd0aDxicj4ifSx7ImtleSI6ImJ1bGxldC0zIiwidmFsdWUiOiIzNDcrIGRldGFpbGVkIGV4ZXJjaXNlIGd1aWRlczxicj4ifSx7ImtleSI6ImJ1bGxldC00IiwidmFsdWUiOiJXb3JsZCByZW5vd25lZCBjb2FjaGVzPGJyPiJ9LHsia2V5IjoiYnVsbGV0LTUiLCJ2YWx1ZSI6IkxpZmUgY2hhbmdpbmcgYWR2aWNlPGJyPiJ9LHsia2V5IjoiYnVsbGV0LTYiLCJ2YWx1ZSI6Ik92ZXIgMSwwMDAsMDAwIGhhcHB5IHVzZXJzPGJyPiJ9LHsia2V5IjoidGltZWxpbmUgdGl0bGUiLCJ2YWx1ZSI6IlNvIGhvdyBkb2VzIG15IGZyZWUgdHJpYWwgd29yaz8ifSx7ImtleSI6ImNhbGxvdXQtYmFkZ2UiLCJ2YWx1ZSI6IjQwJSBPRkYifSx7ImtleSI6ImNhbGxvdXQgdGl0bGUiLCJ2YWx1ZSI6Ikp1c3QgJDEuNzMgcGVyIHdlZWsifSx7ImtleSI6ImNhbGxvdXQgc3VidGl0bGUiLCJ2YWx1ZSI6IjcgZGF5cyBmcmVlLCBjYW5jZWwgYW55dGltZTxicj4ifSx7ImtleSI6InB1cmNoYXNlIGJ1dHRvbiBzdWJ0aXRsZSIsInZhbHVlIjoiNyBkYXlzIGZyZWUgdGhlbiBvbmx5IHt7IHByaW1hcnkucHJpY2UgfX0gcGVyIHlyPGJyPiJ9LHsia2V5IjoiUGFyYWdyYXBoIiwidmFsdWUiOiI8cCBjbGFzcz1cInBhcmFncmFwaC10ZXh0IGxlZnQtYWxpZ25cIj5UaGlzIGlzIHRoZSBwYXJhZ3JhcGggZWxlbWVudDxicj5saW5lIDI8L3A+In0seyJrZXkiOiJGb290bm90ZSIsInZhbHVlIjoiPHAgY2xhc3M9XCJmb290bm90ZS10ZXh0IGxlZnQtYWxpZ25cIj5UaGlzIGlzIHRoZSBmb290bm90ZSBlbGVtZW50PGJyPmxpbmUgMjwvcD4ifSx7ImtleSI6IkhlYWRpbmciLCJ2YWx1ZSI6IkhlYWRpbmc8YnI+bGluZSAyIn0seyJrZXkiOiJTdWJoZWFkaW5nIiwidmFsdWUiOiJUaGlzIGlzIHRoZSBzdWJoZWFkaW5nPGJyPmxpbmUgMiJ9LHsia2V5IjoiQmFkZ2UgVGl0bGUiLCJ2YWx1ZSI6IjctRGF5IEZyZWUgVHJpYWwifSx7ImtleSI6IkNhbGxvdXQgVGl0bGUiLCJ2YWx1ZSI6Ik9ubHkgJDUyL3lyIGZvciBhIGxpbWl0ZWQgdGltZSJ9LHsia2V5IjoiQ2FsbG91dCBTdWJ0aXRsZSIsInZhbHVlIjoiSW5jbHVkZXMgYSA3LWRheSBmcmVlIHRyaWFsIn0seyJrZXkiOiJDYWxsb3V0IEJhZGdlIFRleHQiLCJ2YWx1ZSI6IjQwJSBvZmYifSx7ImtleSI6IlJhdGluZyBWYWx1ZSIsInZhbHVlIjoiNC43In0seyJrZXkiOiJSYXRpbmcgTGFiZWwiLCJ2YWx1ZSI6IkF2ZXJhZ2UgUmF0aW5nIn0seyJrZXkiOiJSZXZpZXcgVGl0bGUiLCJ2YWx1ZSI6IlRoaXMgaXMgdGhlIGJlc3QgYXBwIG9mIGFsbCB0aW1lIn0seyJrZXkiOiJSZXZpZXcgQm9keSIsInZhbHVlIjoiVGhpcyBpcyB0aGUgcGFyYWdyYXBoIGVsZW1lbnQifSx7ImtleSI6IlJldmlldyBBdXRob3IiLCJ2YWx1ZSI6IuKAkyBKYWtlIE1vciJ9LHsia2V5IjoiTGlzdCBJdGVtIFRleHQiLCJ2YWx1ZSI6IlRoaXMgaXMgYSBsaXN0IGl0ZW0ifSx7ImtleSI6Ikxpc3QgSXRlbSBUaXRsZSIsInZhbHVlIjoiSGVhZGluZyJ9LHsia2V5IjoiTGlzdCBJdGVtIFN1YnRpdGxlIiwidmFsdWUiOiJUaGlzIGlzIHRoZSBzdWJoZWFkaW5nIn0seyJrZXkiOiJDaGVja2xpc3QgUm93IDEiLCJ2YWx1ZSI6IkNhbmNlbCBhbnl0aW1lIGluIHNlY29uZHMifSx7ImtleSI6IkNoZWNrbGlzdCBSb3cgMiIsInZhbHVlIjoiVG9ucyBvZiBpbmNyZWRpYmxlIGZlYXR1cmVzIn0seyJrZXkiOiJDaGVja2xpc3QgUm93IDMiLCJ2YWx1ZSI6IlBheW1lbnQgcHJvdGVjdGlvbiBwb2xpY3kifSx7ImtleSI6IkNoZWNrbGlzdCBSb3cgNCIsInZhbHVlIjoiRXhjZWxsZW50IGN1c3RvbWVyIHN1cHBvcnQifSx7ImtleSI6IkZBUSBRdWVzdGlvbiIsInZhbHVlIjoiRG8geW91IGhhdmUgZWxlbWVudHMgZm9yIEZBUXM/In0seyJrZXkiOiJGQVEgQW5zd2VyIiwidmFsdWUiOiJZZXMhIFdlIGFic29sdXRlbHkgZG8uIFdlIGhhdmUgbW9yZSBlbGVtZW50cyB0aGFuIHlvdSBtaWdodCB0aGluayA7KSJ9LHsia2V5IjoiVGFibGUgQ29sIDEgVGl0bGUiLCJ2YWx1ZSI6IkhlYWRlciJ9LHsia2V5IjoiVGFibGUgQ29sIDIgVGl0bGUiLCJ2YWx1ZSI6IkZyZWUifSx7ImtleSI6IlRhYmxlIENvbCAzIFRpdGxlIiwidmFsdWUiOiJQcmVtaXVtIn0seyJrZXkiOiJUYWJsZSBSb3cgMSIsInZhbHVlIjoiRmVhdHVyZSAxIn0seyJrZXkiOiJUYWJsZSBSb3cgMiIsInZhbHVlIjoiRmVhdHVyZSAyIn0seyJrZXkiOiJUYWJsZSBSb3cgMyIsInZhbHVlIjoiRmVhdHVyZSAzIn0seyJrZXkiOiJUYWJsZSBSb3cgNCIsInZhbHVlIjoiRmVhdHVyZSA0In0seyJrZXkiOiJUZWFtIE1lc3NhZ2UgVGl0bGUiLCJ2YWx1ZSI6Ik91ciBQcm9taXNlIn0seyJrZXkiOiJUZWFtIE1lc3NhZ2UgQm9keSIsInZhbHVlIjoiUGllZCBQaXBlciBoYXMgY2hhbmdlZCBtYW55IGxhbmRzY2FwZXMuIENvbXByZXNzaW9uLiBEYXRhLiBUaGUgSW50ZXJuZXQuPGJyPjxicj5PdXIgcHJvbWlzZSBpcyB0byBjb250aW51ZSB0byBjaGFuZ2UgdGhpbmdzIOKAlCBub3QgZm9yIHRoZSBzYWtlIG9mIGNoYW5nZSwgYnV0IHRvIG1ha2UgdGhlIHdvcmxkIGEgYmV0dGVyIHBsYWNlLCB1c2luZyBtaWRkbGUgb3V0IGNvbXByZXNzaW9uIGZvciBsb3NzbGVzcyBkYXRhIHByZXNlcnZhdGlvbi48YnI+PGJyPkFsc28sIGxvc2luZyBULkouIE1pbGxlciBpbiBzZWFzb24gNSB3YXMgYWJzb2x1dGVseSBoZWFyYnJlYWtpbmcuPGJyPiJ9LHsia2V5IjoiVGVhbSBNZXNzYWdlIEF1dGhvciIsInZhbHVlIjoiUmljaGFyZCBIZW5kcmlja3MifSx7ImtleSI6IlRlYW0gTWVzc2FnZSBBdXRob3IgVGl0bGUiLCJ2YWx1ZSI6IkZvdW5kZXIgJmFtcDsmbmJzcDtDRU8ifSx7ImtleSI6IkZlYXR1cmUgSGVhZGluZyIsInZhbHVlIjoiSGVhZGluZyJ9LHsia2V5IjoiRmVhdHVyZSBTdWJoZWFkaW5nIiwidmFsdWUiOiJUaGlzIGlzIHRoZSBzdWJoZWFkaW5nIn0seyJrZXkiOiJQcm9kdWN0IENUQSBTdWJ0aXRsZSIsInZhbHVlIjoiV2UnbGwgcmVtaW5kIHlvdSBiZWZvcmUgeW91J3JlIGNoYXJnZWQifSx7ImtleSI6IlByaW1hcnkgQnV0dG9uIExpbmUgMiIsInZhbHVlIjoiT25seSAkMi45OS93ZWVrIGFmdGVyIHlvdXIgdHJpYWwifSx7ImtleSI6IkJ1dHRvbiBTZWN0aW9uIFRpdGxlIiwidmFsdWUiOiJOb3QgY29udmluY2VkIHlldD8ifSx7ImtleSI6Im9wZW4tdXJsLTEiLCJ2YWx1ZSI6IlByaXZhY3kgUG9saWN5Iiwic2tpcElubmVySFRNTCI6ZmFsc2UsInRhZ05hbWUiOiJhIiwic3ViVHlwZSI6InZhciIsInByb3BlcnRpZXMiOlt7InByZWZpeCI6ImRlZmF1bHQiLCJwcm9wZXJ0eSI6eyJ0eXBlIjoiY2xpY2stYmVoYXZpb3IiLCJjbGlja0JlaGF2aW9yIjp7InR5cGUiOiJvcGVuLXVybCIsInVybCI6Imh0dHBzOi8vbW9vbnNldGxhYnMuY29tL2ZpdG5lc3MtYWkvcHJpdmFjeV9wb2xpY3kuaHRtbCJ9fX1dfSx7ImtleSI6Im9wZW4tdXJsLTIiLCJ2YWx1ZSI6IlRlcm1zIG9mIFVzZSIsInNraXBJbm5lckhUTUwiOmZhbHNlLCJ0YWdOYW1lIjoiYSIsInN1YlR5cGUiOiJ2YXIiLCJwcm9wZXJ0aWVzIjpbeyJwcmVmaXgiOiJkZWZhdWx0IiwicHJvcGVydHkiOnsidHlwZSI6ImNsaWNrLWJlaGF2aW9yIiwiY2xpY2tCZWhhdmlvciI6eyJ0eXBlIjoib3Blbi11cmwiLCJ1cmwiOiJodHRwczovL21vb25zZXRsYWJzLmNvbS9maXRuZXNzLWFpL3Rlcm1zX2FuZF9jb25kaXRpb25zLmh0bWwifX19XX0seyJrZXkiOiJjbG9zZS0xIiwidmFsdWUiOiJFWElUIiwic2tpcElubmVySFRNTCI6ZmFsc2UsInRhZ05hbWUiOiJhIiwic3ViVHlwZSI6InZhciIsInByb3BlcnRpZXMiOlt7InByZWZpeCI6ImRlZmF1bHQiLCJwcm9wZXJ0eSI6eyJ0eXBlIjoiY2xpY2stYmVoYXZpb3IiLCJjbGlja0JlaGF2aW9yIjp7InR5cGUiOiJjbG9zZSJ9fX1dfSx7ImtleSI6InJlc3RvcmUtMSIsInZhbHVlIjoiPGRpdiBjbGFzcz1cInRleHQtYmxvY2stMjFcIj5BbHJlYWR5IGEgbWVtYmVyPzwvZGl2PjxkaXYgY2xhc3M9XCJ0ZXh0LWJsb2NrLTIwXCI+UmVzdG9yZTwvZGl2PiIsInNraXBJbm5lckhUTUwiOmZhbHNlLCJ0YWdOYW1lIjoiZGl2Iiwic3ViVHlwZSI6InZhciIsInByb3BlcnRpZXMiOlt7InByZWZpeCI6ImRlZmF1bHQiLCJwcm9wZXJ0eSI6eyJ0eXBlIjoiY2xpY2stYmVoYXZpb3IiLCJjbGlja0JlaGF2aW9yIjp7InR5cGUiOiJyZXN0b3JlIn19fV19LHsia2V5IjoiY3VzdG9tLTEiLCJ2YWx1ZSI6Ik1lc3NhZ2UgVXMiLCJza2lwSW5uZXJIVE1MIjpmYWxzZSwidGFnTmFtZSI6ImRpdiIsInN1YlR5cGUiOiJ2YXIiLCJwcm9wZXJ0aWVzIjpbeyJwcmVmaXgiOiJkZWZhdWx0IiwicHJvcGVydHkiOnsidHlwZSI6ImNsaWNrLWJlaGF2aW9yIiwiY2xpY2tCZWhhdmlvciI6eyJ0eXBlIjoiY3VzdG9tIiwiZGF0YSI6ImludGVyY29tIn19fV19XX1d",
    "substitutions": [{
      "key": "Title",
      "value": "Test"
    }, {
      "key": "Timeline Row 1 Title",
      "value": "Today",
      "freeTrialValue": "Today"
    }, {
      "key": "Timeline Row 1 Subtitle",
      "value": "Get full access to all our features"
    }, {
      "key": "Timeline Row 2 Title",
      "value": "In 5 Days"
    }, {
      "key": "Timeline Row 2 Subtitle",
      "value": "Get a reminder about when your free trial ends"
    }, {
      "key": "Timeline Row 3 Title",
      "value": "In 7 Days"
    }, {
      "key": "Timeline Row 3 Subtitle",
      "value": "Get billed, unless you cancel anytime before"
    }, {
      "key": "Restore Label",
      "value": "Already subscribed?"
    }, {
      "key": "Primary Product Strike Through",
      "value": "$0.00"
    }, {
      "key": "Primary Product Line 1",
      "value": "$0.00 per period"
    }, {
      "key": "Primary Product Line 2",
      "value": "0-day free trial"
    }, {
      "key": "Primary Product Badge",
      "value": "Best Value"
    }, {
      "key": "Secondary Product Line 1",
      "value": "$0.00 per period"
    }, {
      "key": "Secondary Product Line 2",
      "value": "0-day free trial"
    }, {
      "key": "Tertiary Product Line 1",
      "value": "$0.00 per period"
    }, {
      "key": "Tertiary Product Line 2",
      "value": "0-day free trial"
    }, {
      "key": "Primary CTA Subtitle",
      "value": "$0.00/yr After Your Free Trial"
    }, {
      "key": "Secondary CTA Subtitle",
      "value": "$0.00/yr After Your Free Trial"
    }, {
      "key": "Tertiary CTA Subtitle",
      "value": "$0.00/yr After Your Free Trial"
    }, {
      "key": "Other Plans Button",
      "value": "Other Plans"
    }, {
      "key": "Purchase Primary",
      "value": "Continue"
    }, {
      "key": "Purchase Secondary",
      "value": "Continue"
    }, {
      "key": "Purchase Tertiary",
      "value": "Continue"
    }, {
      "key": "purchase-primary",
      "value": "Continue"
    }, {
      "key": "purchase-secondary",
      "value": "Continue"
    }, {
      "key": "purchase-tertiary",
      "value": "Continue"
    }, {
      "key": "title",
      "value": "{{primary.trialPeriodDays}} days FREE then {{primary.dailyPrice}}/day billed every {{primary.period}}"
    }, {
      "key": "subtitle",
      "value": "Hey  {{ user.firstName }}!\nOnly $1.73 per week billed annually. That's 50-100x cheaper than a trainer.<br>"
    }, {
      "key": "bullet-1",
      "value": "Optimized workouts everyday<br>"
    }, {
      "key": "bullet-2",
      "value": "Adapted to your strength<br>"
    }, {
      "key": "bullet-3",
      "value": "347+ detailed exercise guides<br>"
    }, {
      "key": "bullet-4",
      "value": "World renowned coaches<br>"
    }, {
      "key": "bullet-5",
      "value": "Life changing advice<br>"
    }, {
      "key": "bullet-6",
      "value": "Over 1,000,000 happy users<br>"
    }, {
      "key": "timeline title",
      "value": "So how does my free trial work?"
    }, {
      "key": "callout-badge",
      "value": "40% OFF"
    }, {
      "key": "callout title",
      "value": "Just $1.73 per week"
    }, {
      "key": "callout subtitle",
      "value": "7 days free, cancel anytime<br>"
    }, {
      "key": "purchase button subtitle",
      "value": "7 days free then only {{ primary.price }} per yr<br>"
    }, {
      "key": "Paragraph",
      "value": "<p class=\"paragraph-text left-align\">This is the paragraph element<br>line 2</p>"
    }, {
      "key": "Footnote",
      "value": "<p class=\"footnote-text left-align\">This is the footnote element<br>line 2</p>"
    }, {
      "key": "Heading",
      "value": "Heading<br>line 2"
    }, {
      "key": "Subheading",
      "value": "This is the subheading<br>line 2"
    }, {
      "key": "Badge Title",
      "value": "7-Day Free Trial"
    }, {
      "key": "Callout Title",
      "value": "Only $52/yr for a limited time"
    }, {
      "key": "Callout Subtitle",
      "value": "Includes a 7-day free trial"
    }, {
      "key": "Callout Badge Text",
      "value": "40% off"
    }, {
      "key": "Rating Value",
      "value": "4.7"
    }, {
      "key": "Rating Label",
      "value": "Average Rating"
    }, {
      "key": "Review Title",
      "value": "This is the best app of all time"
    }, {
      "key": "Review Body",
      "value": "This is the paragraph element"
    }, {
      "key": "Review Author",
      "value": "– Jake Mor"
    }, {
      "key": "List Item Text",
      "value": "This is a list item"
    }, {
      "key": "List Item Title",
      "value": "Heading"
    }, {
      "key": "List Item Subtitle",
      "value": "This is the subheading"
    }, {
      "key": "Checklist Row 1",
      "value": "Cancel anytime in seconds"
    }, {
      "key": "Checklist Row 2",
      "value": "Tons of incredible features"
    }, {
      "key": "Checklist Row 3",
      "value": "Payment protection policy"
    }, {
      "key": "Checklist Row 4",
      "value": "Excellent customer support"
    }, {
      "key": "FAQ Question",
      "value": "Do you have elements for FAQs?"
    }, {
      "key": "FAQ Answer",
      "value": "Yes! We absolutely do. We have more elements than you might think ;)"
    }, {
      "key": "Table Col 1 Title",
      "value": "Header"
    }, {
      "key": "Table Col 2 Title",
      "value": "Free"
    }, {
      "key": "Table Col 3 Title",
      "value": "Premium"
    }, {
      "key": "Table Row 1",
      "value": "Feature 1"
    }, {
      "key": "Table Row 2",
      "value": "Feature 2"
    }, {
      "key": "Table Row 3",
      "value": "Feature 3"
    }, {
      "key": "Table Row 4",
      "value": "Feature 4"
    }, {
      "key": "Team Message Title",
      "value": "Our Promise"
    }, {
      "key": "Team Message Body",
      "value": "Pied Piper has changed many landscapes. Compression. Data. The Internet.<br><br>Our promise is to continue to change things — not for the sake of change, but to make the world a better place, using middle out compression for lossless data preservation.<br><br>Also, losing T.J. Miller in season 5 was absolutely hearbreaking.<br>"
    }, {
      "key": "Team Message Author",
      "value": "Richard Hendricks"
    }, {
      "key": "Team Message Author Title",
      "value": "Founder &amp;&nbsp;CEO"
    }, {
      "key": "Feature Heading",
      "value": "Heading"
    }, {
      "key": "Feature Subheading",
      "value": "This is the subheading"
    }, {
      "key": "Product CTA Subtitle",
      "value": "We'll remind you before you're charged"
    }, {
      "key": "Primary Button Line 2",
      "value": "Only $2.99/week after your trial"
    }, {
      "key": "Button Section Title",
      "value": "Not convinced yet?"
    }, {
      "key": "open-url-1",
      "value": "Privacy Policy",
      "skipInnerHTML": false,
      "tagName": "a",
      "subType": "var",
      "properties": [{
        "prefix": "default",
        "property": {
          "type": "click-behavior",
          "clickBehavior": {
            "type": "open-url",
            "url": "https://moonsetlabs.com/fitness-ai/privacy_policy.html"
          }
        }
      }]
    }, {
      "key": "open-url-2",
      "value": "Terms of Use",
      "skipInnerHTML": false,
      "tagName": "a",
      "subType": "var",
      "properties": [{
        "prefix": "default",
        "property": {
          "type": "click-behavior",
          "clickBehavior": {
            "type": "open-url",
            "url": "https://moonsetlabs.com/fitness-ai/terms_and_conditions.html"
          }
        }
      }]
    }, {
      "key": "close-1",
      "value": "EXIT",
      "skipInnerHTML": false,
      "tagName": "a",
      "subType": "var",
      "properties": [{
        "prefix": "default",
        "property": {
          "type": "click-behavior",
          "clickBehavior": {
            "type": "close"
          }
        }
      }]
    }, {
      "key": "restore-1",
      "value": "<div class=\"text-block-21\">Already a member?</div><div class=\"text-block-20\">Restore</div>",
      "skipInnerHTML": false,
      "tagName": "div",
      "subType": "var",
      "properties": [{
        "prefix": "default",
        "property": {
          "type": "click-behavior",
          "clickBehavior": {
            "type": "restore"
          }
        }
      }]
    }, {
      "key": "custom-1",
      "value": "Message Us",
      "skipInnerHTML": false,
      "tagName": "div",
      "subType": "var",
      "properties": [{
        "prefix": "default",
        "property": {
          "type": "click-behavior",
          "clickBehavior": {
            "type": "custom",
            "data": "intercom"
          }
        }
      }]
    }],
    "products_v2": [
      {
        "reference_name": "primary",
        "store_product": {
          "store": "APP_STORE",
          "product_identifier": "sk.superwall.annual.89.99_7"
        },
        "entitlements": [
          {
            "identifier": "test",
            "type": "SERVICE_LEVEL"
          }
        ]
      },
      {
        "store_product": {
          "store":"PLAY_STORE",
          "product_identifier":"com.ui_tests.quarterly2",
          "base_plan_identifier":"test-2",
          "offer":{"type":"AUTOMATIC"}
        },
        "entitlements":[]
      },
      {
        "reference_name": "primary",
        "store_product": {
          "store": "PLAY_STORE",
          "product_identifier": "my-android-product",
          "base_plan_identifier": "base-plan",
          "offer": {
            "type": "AUTOMATIC"
          }
        }
      }
    ],
    "presentation_condition": "CHECK_USER_SUBSCRIPTION",
    "presentation_delay": 0,
    "presentation_style": "FULLSCREEN",
    "presentation_style_v2": "FULLSCREEN",
    "launch_option": "EXPLICIT",
    "dismissal_option": "NORMAL",
    "background_color_hex": "#000000"
  }],
  "log_level": 10,
  "localization": {
    "locales": []
  },
  "postback": {
    "delay": 5000,
    "products": [{
      "platform": "ios",
      "identifier": "sk.superwall.annual.89.99_7"
    }]
  },
  "app_session_timeout_ms": 3600000,
  "tests": {
    "dns_resolution": [{
      "hostname": "www.fitnessai.com"
    }]
  },
  "disable_preload": {
    "all": false,
    "triggers": []
  },
  "products": [
    {
      "store_product": {
        "store": "APP_STORE",
        "product_identifier": "com.ui_tests.monthly"
      },
      "entitlements": [
        {
          "identifier": "default",
          "type": "SERVICE_LEVEL"
        }
      ]
    },
    {
      "store_product": {
        "store": "APP_STORE",
        "product_identifier": "com.ui_tests.annual"
      },
      "entitlements": [
        {
          "identifier": "default",
          "type": "SERVICE_LEVEL"
        }
      ]
    },
    {
      "store_product": {
        "store": "APP_STORE",
        "product_identifier": "incorrect_product_identifier"
      },
      "entitlements": [
        {
          "identifier": "default",
          "type": "SERVICE_LEVEL"
        }
      ]
    }
  ]
}
"""#

final class ConfigTypeTests: XCTestCase {
  func testParseConfig() throws {
    let parsedResponse = try! JSONDecoder.fromSnakeCase.decode(
      Config.self,
      from: response.data(using: .utf8)!
    )

    XCTAssertTrue(parsedResponse.paywalls.first!.products.count != 0)
    guard let trigger = parsedResponse.triggers.filter({ $0.placementName == "MyEvent" }).first
    else {
      return XCTFail("opened_application trigger not found")
    }

    let firstRule = trigger.audiences[0]
    XCTAssertNil(firstRule.expression)
    XCTAssertEqual(firstRule.experiment.id, "80")

    switch firstRule.experiment.variants.first!.type {
    case .treatment:
      throw TestError.init("Expecting Holdout")
    case .holdout:
      XCTAssertEqual(firstRule.experiment.variants.first!.id, "218")
    }

    let secondVariant = firstRule.experiment.variants[1]
    switch secondVariant.type {
    case .holdout:
      throw TestError.init("Expecting holdout")
    case .treatment:
      XCTAssertEqual(secondVariant.paywallId, "example-paywall-4de1-2022-03-15")
      XCTAssertEqual(secondVariant.id, "219")
    }
  }
}
