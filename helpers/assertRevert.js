/*    
    copyright 2018 to the Commonwealth-HQ Authors

    This file is part of Commonwealth-HQ.

    Commonwealth-HQ is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Commonwealth-HQ is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Commonwealth-HQ.  If not, see <https://www.gnu.org/licenses/>.
*/

export default async function assertRevert(promise, invariants = () => {}) {
  try {
    await promise;
    assert.fail('Expected revert not received');
  } catch (error) {
    const revertFound = error.message.search('revert') >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
    invariants.call()
  }
}
