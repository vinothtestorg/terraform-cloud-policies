mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-tfplan-pass.sentinel"
  }
}
import "module" "tag_reference" {
  source = "../../testdata/tag_reference-stale.sentinel"
}
test {
  rules = {
    main = false
  }
}
