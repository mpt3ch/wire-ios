//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import WireDataModel

extension UserType {
    var nameAccentColor: UIColor? {
        return UIColor.nameColor(for: accentColorValue, variant: ColorScheme.default.variant)
    }
}

extension ZMUser {

    var canSeeServices: Bool {
        #if ADD_SERVICE_DISABLED
        return false
        #else
        return hasTeam
        #endif
    }

    /// Blocks user if not already blocked and vice versa.
    func toggleBlocked() {
        if isBlocked {
            accept()
        } else {
            block()
        }
    }

}
