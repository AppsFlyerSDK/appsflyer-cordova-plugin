/* eslint-env jasmine */
/* global cordova */

exports.defineAutoTests = function () {

    describe('Simple sanity', function () {
        it('this is success', function () {
            expect(1).toBe(1);
        });

        it('this is failure', function () {
            expect(1).toBe(2);
        });
    });
};
