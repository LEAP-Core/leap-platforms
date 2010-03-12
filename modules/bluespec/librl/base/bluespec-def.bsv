//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

//
// Hacks for defining type aliases within a module to work around lack of
// "typedef" inside module scope.
//
typeclass Alias#(type a, type b)
    dependencies (a determines b);
endtypeclass

instance Alias#(a,a);
endinstance

typeclass NumAlias#(numeric type a, numeric type b)
    dependencies (a determines b, b determines a);
endtypeclass

instance NumAlias#(a,a);
endinstance



//
// NumTypeParam is useful for passing a numeric type as a parameter to a
// module when the type is not part of the module's interface.  Ideally,
// Bluespec would permit type parameters to modules.  This is an
// intermediate step.
//
// Usage:
//
//   module mkMod0#(NumTypeParam#(n_ENTRIES) p) (BASE);
//       Vector#(n_ENTRIES, Bit#(1)) v = ?;
//   endmodule
//
//   module mkMod1 ();
//       NumTypeParam#(1024) p = ?;
//       BASE b <- mkMod0(p);
//   endmodule
//

typedef Bit#(n) NumTypeParam#(numeric type n);
