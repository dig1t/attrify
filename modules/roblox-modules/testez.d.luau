declare function afterAll(callback: (context: { [any]: any }) -> ()): ()
declare function afterEach(callback: (context: { [any]: any }) -> ()): ()

declare function beforeAll(callback: (context: { [any]: any }) -> ()): ()
declare function beforeEach(callback: (context: { [any]: any }) -> ()): ()

declare function describe(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function describeFOCUS(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function fdescribe(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function describeSKIP(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function xdescribe(phrase: string, callback: (context: { [any]: any }) -> ()): ()

declare function expect(value: any): any

declare function FIXME(optionalMessage: string?): ()
declare function FOCUS(): ()
declare function SKIP(): ()

declare function it(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function itFOCUS(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function fit(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function itSKIP(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function xit(phrase: string, callback: (context: { [any]: any }) -> ()): ()
declare function itFIXME(phrase: string, callback: (context: { [any]: any }) -> ()): ()
