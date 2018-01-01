#
# If there is a - possibly .gitignored - tap-info.sh file read it.
# It could store PUBLISHER and PUBLISHER_TAP
#

source_publisher_overrides()
{
   local filename

   [ ! -d "mulle-project" ] && echo "mulle-project not found" >&2 && exit 1

   # old name
   filename="mulle-project/publisher-info.sh"
   if [ -f "${filename}" ]
   then
      if [ "${VERBOSE}" = "YES" ]
      then
         echo "reading \"${filename}\"" >&2
      fi
      . "${filename}"
      return 0
   fi
   return 1
}


source_publisher_defaults()
{
   if [ ! -z "${PUBLISHER_INFO_SH}" ]
   then
      if [ -f "${PUBLISHER_INFO_SH}" ]
      then
         if [ "${VERBOSE}" = "YES" ]
         then
            echo "reading \"${PUBLISHER_INFO_SH}\" as defined by PUBLISHER_INFO_SH" >&2
         fi
         . "${PUBLISHER_INFO_SH}"
         return 0
      fi

      echo "PUBLISHER_INFO_SH is defined as \"${PUBLISHER_INFO_SH}\" but is missing as a file" >&2
      exit 1
   fi

   if [ ! -z "${DEPENDENCIES_DIR}" ]
   then
      if [ -f "${DEPENDENCIES_DIR}/share/publisher-info.sh" ]
      then
         if [ "${VERBOSE}" = "YES" ]
         then
            echo "reading \"${DEPENDENCIES_DIR}/share/publisher-info.sh\"" >&2
         fi
         . "${DEPENDENCIES_DIR}/share/publisher-info.sh"
         return 0
      fi
   fi

   return 1
}


if ! source_publisher_overrides
then
   if ! source_publisher_defaults
   then
      echo "No publisher info found" >&2
   fi
fi
