mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-tfplan-pass.sentinel"
  }
}
import "module" "tag_reference" {
  source = "../../modules/tag_reference.sentinel"
}
test {
  rules = {
    main = true
  }
}
