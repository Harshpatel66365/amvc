using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Reflection;
using System.Text;
using Core;

namespace DAL.Utility
{
    public class RetailerCommonDal : BaseSQLManager<MyRetailerConnectionString>
    {
        #region CommanCommandcheck
        public static SqlCommand CommanCommandParam(dynamic obj, SqlCommand cmd)
        {
            SqlParameter sp = null;
            return CommanCommandParam(obj, cmd, "", ref sp);
        }
        #endregion

        #region CommanCommandcheck
        public static SqlCommand CommanCommandParam(dynamic obj, SqlCommand cmd, string OutParam, ref SqlParameter sp)
        {
            PropertyInfo[] propertyInfo = obj.GetType().GetProperties();

            foreach (var item in propertyInfo)
            {
                if (item.PropertyType == typeof(string))
                {
                    if (!string.IsNullOrEmpty(item.GetValue(obj)))
                    {
                        if (item.Name.Contains("Date"))
                        {
                            cmd.Parameters.AddWithValue("@" + item.Name, Convert.ToDateTime(item.GetValue(obj)));
                        }
                        else
                        {
                            cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));
                        }
                    }
                }
                else if (item.PropertyType == typeof(int))
                {
                    if (item.Name == OutParam && !string.IsNullOrEmpty(OutParam))
                    {
                        sp = new SqlParameter("@" + item.Name, SqlDbType.Int);
                        sp.Direction = ParameterDirection.InputOutput;
                        sp.Value = item.GetValue(obj);
                        cmd.Parameters.Add(sp);
                    }
                    else
                    {
                        if (item.GetValue(obj) > 0)
                        {
                            cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));
                        }
                    }
                }
                else if (item.PropertyType == typeof(Int64) || item.PropertyType == typeof(long))
                {
                    if (item.Name == OutParam && !string.IsNullOrEmpty(OutParam))
                    {
                        sp = new SqlParameter("@" + item.Name, SqlDbType.BigInt);
                        sp.Direction = ParameterDirection.InputOutput;
                        sp.Value = item.GetValue(obj);
                        cmd.Parameters.Add(sp);
                    }
                    else
                    {
                        if (item.GetValue(obj) > 0)
                        {
                            cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));
                        }
                    }
                }
                else if (item.PropertyType == typeof(float))
                {
                    if (item.GetValue(obj) > 0)
                    {
                        cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));
                    }
                }
                else if (item.PropertyType == typeof(decimal))
                {

                    if (item.GetValue(obj) > 0)
                    {
                        cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));
                    }
                }
                else if (item.PropertyType == typeof(bool))
                {
                    cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));
                }
                else if (item.PropertyType == typeof(char))
                {
                    if (!string.IsNullOrEmpty(item.GetValue(obj)))
                    {
                        cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));

                    }
                }
                else if (item.PropertyType == typeof(DateTime))
                {
                    if (item.GetValue(obj) != null)
                    {
                        cmd.Parameters.AddWithValue("@" + item.Name, item.GetValue(obj));

                    }
                }
                else
                {

                }
            }
            return cmd;
        }
        #endregion

        #region CommonDatagetInObj
        public static void CommonDatagetInObj(dynamic Inputobj, string SPName, ref dynamic resultobj)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = SPName;
            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            CommonDal.CommanCommandParam(Inputobj, cmd);
            SqlDataReader dr = null;
            ExecuteDataReader(cmd, ref dr);
            DrToObject(dr, ref resultobj);
            dr.Close();
            ForceCloseConnection(cmd);

        }
        #endregion

        #region DrToObject
        public static void DrToObject(SqlDataReader dr, ref dynamic resultobj)
        {
            PropertyInfo[] propertyInfo = resultobj.GetType().GetProperties();
            while (dr.Read())
            {
                foreach (var item in propertyInfo)
                {
                    if (item.PropertyType == typeof(string))
                    {
                        item.SetValue(resultobj, GetField(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(int))
                    {
                        item.SetValue(resultobj, GetFieldInt(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(Int64) || item.PropertyType == typeof(long))
                    {
                        item.SetValue(resultobj, GetFieldInt64(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(bool))
                    {
                        item.SetValue(resultobj, GetFieldBool(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(decimal))
                    {
                        item.SetValue(resultobj, GetFieldDecimal(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(char))
                    {
                        item.SetValue(resultobj, GetField(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(DateTime))
                    {
                        item.SetValue(resultobj, GetFieldDateTimeNullable(dr, item.Name));
                    }
                    else if (item.PropertyType == typeof(float))
                    {
                        item.SetValue(resultobj, GetFieldSingle(dr, item.Name));
                    }
                }
            }
        }
        #endregion

        #region GetListing
        public static List<Dictionary<string, object>> CommanListingDal(dynamic obj, string SpName)
        {
            List<Dictionary<string, object>> secondresult = null;
            return CommanListingDal(obj, SpName, ref secondresult);
        }
        #endregion

        #region GetListing
        public static List<Dictionary<string, object>> CommanListingDal(dynamic obj, string SpName, ref List<Dictionary<string, object>> SecondResult)
        {
            List<Dictionary<string, object>> result = new List<Dictionary<string, object>>();
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = SpName;
            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            CommonDal.CommanCommandParam(obj, cmd);
            SqlDataReader dr = null;
            ExecuteDataReader(cmd, ref dr);
            result = DataReaderToDictionaryList(dr);
            if (SecondResult != null)
            {
                if (dr.NextResult())
                {
                    SecondResult = DataReaderToDictionaryList(dr);
                }
            }
            dr.Close();
            ForceCloseConnection(cmd);
            return result;
        }
        #endregion        

        #region CommonAddEdit
        public static Int64 CommonAddEdit(dynamic obj, string SpName, string OutParam)
        {
            SqlCommand cmd = null;
            return CommonAddEdit(obj, SpName, cmd, OutParam);
        }
        #endregion

        public static Int64 CommonAddEdit(dynamic obj, string SpName, SqlCommand cmd, string OutParam)
        {
            return CommonAddEdit(obj, SpName, cmd, OutParam, true);
        }

        #region CommonAddEdit
        public static Int64 CommonAddEdit(dynamic obj, string SpName, SqlCommand cmd, string OutParam, bool ISClearCommoand)
        {
            Int64 ID = 0;
            bool Transction = true;
            if (cmd == null)
            {
                cmd = new SqlCommand();
                Transction = false;
            }
            try
            {
                if (ISClearCommoand)
                {
                    cmd.Parameters.Clear();
                }
                cmd.CommandText = SpName;
                cmd.CommandType = CommandType.StoredProcedure;
                SqlParameter sp = null;
                CommonDal.CommanCommandParam(obj, cmd, OutParam, ref sp);
                if (Transction == false)
                {
                    ExecuteNonQuery(cmd);
                    ID = Convert.ToInt64(sp.Value);
                    ForceCloseConnection(cmd);
                }
                else
                {
                    ExecuteNonQuery(cmd, true);
                    ID = Convert.ToInt64(sp.Value);
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }
            return ID;
        }
        #endregion

        #region GetByID
        public static DataTable GetByID(Int64 ID, string SpParamName, string SPName)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = SPName;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@" + SpParamName, ID);
            return ExecuteDataTable(cmd);
        }
        #endregion

        #region GetDetailByID
        public static DataSet GetDetailByID(dynamic obj, string SPName)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = SPName;
            cmd.CommandType = CommandType.StoredProcedure;
            CommanCommandParam(obj, cmd);
            return ExecuteDataset(cmd);
        }
        #endregion

        #region GetDetailByID
        public static Dictionary<string, object> GetObjByID(dynamic obj, string SPName)
        {
            Dictionary<string, object> result = new Dictionary<string, object>();
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = SPName;
            cmd.CommandType = CommandType.StoredProcedure;
            CommonDal.CommanCommandParam(obj, cmd);
            SqlDataReader dr = null;
            ExecuteDataReader(cmd, ref dr);
            result = DataReaderToDictionary(dr);
            return result;
        }
        #endregion
    }
}
