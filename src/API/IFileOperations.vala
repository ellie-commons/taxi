/***
  Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see <http://www.gnu.org/licenses>
***/

namespace Taxi {

    interface IFileOperations : Object {

        public signal void operation_added (IOperationInfo operation);
        public signal void operation_removed (IOperationInfo operation);
        public async abstract bool delete_recursive (
            File file,
            Cancellable? cancellable
        ) throws Error;

        public async abstract List<FileInfo> get_file_list (File file) throws Error;

        public async abstract void copy_recursive (
            File source,
            File destination,
            FileCopyFlags flags = FileCopyFlags.NONE,
            Cancellable? cancellable = null
        ) throws Error;
    }
}
