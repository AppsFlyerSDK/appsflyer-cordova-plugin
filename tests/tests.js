/* eslint-env jasmine */
/* global cordova */

exports.defineAutoTests = function () {

    describe('awesome tests', function () {
        it('do something sync', function () {
            expect(1).toBe(1);
        });

        it('do something async using callbacks', function (done) {
            setTimeout(function () {
                expect(1).toBe(1);
                done();
            }, 100);
        });

        it("do something async using promises", function () {
            let value = 1;
            expect(value).toBeGreaterThan(0);
        });

        it("do something async using async/await", async function () {
            let value = 1;
            expect(value).toBeGreaterThan(0);
        });
    });
};
