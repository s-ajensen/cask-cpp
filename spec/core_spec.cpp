#include "catch.hpp"
#include "bdd.hpp"
#include "core.hpp"

describe("Core tests", []{

  it("fails", [] {
    should_eq(0, 1);
    });
});//