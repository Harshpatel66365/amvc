SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO




-- [sm_GetStoreMaster] @mode= 5,@master_id = 2358804 ,@PageNo=1,@PageSize=50,@dept_id='2,3' ,@only_discounted_items = 1, @pro_is_in_new_arrivals=  1
ALTER PROCEDURE [dbo].[sm_GetStoreMaster]
	@mode int,
	@PageNo int = 0,
	@PageSize int = 0,
	@item_id int = 0,
	@color varchar(max) = '',
	@size varchar(max) = '',
	@dept_id varchar(max) = '',
	@prod_id varchar(max) = '',
	@product_ids varchar(max) = '',
	@brand_id varchar(max) = '',
	@style_id varchar(max) = '',
	@coit_code varchaR(max) = '',
	@lot_srno varchar(max) = '',
	@minPrice float = 0,
	@maxPrice float = 0,
	@minDiscount float = 0,
	@maxDiscount float = 0,
	@sortby varchar(10) = '',
	@sortmode varchar(10) = '',
	@master_id int=0,
	@searchText varchar(250) = '',
	@pro_is_in_homepage bit = 0,
	@pro_is_in_new_arrivals bit = 0,
	@pro_is_in_best_sellers bit = 0,
	@pro_is_in_pick_of_week bit = 0,
	@pro_is_in_recommend bit = 0,
	@not_in_master_id int =0,
	@pro_is_in_sale bit = 0,
	@only_discounted_items bit=0,
	@pro_is_in_feature bit=  0,
	@accessories_dept varchar(10)= '',
	@OccassionName VARCHAR(255) = '',
	@HellType VARCHAR(MAX) = '',
	@UpperMaterial VARCHAR(max) = '',
	@BranchID varchar(max)=''
as
begin
	
  	DECLARE @ExtraFieldIDs VARCHAR(MAX) = ''
	SELECT @ExtraFieldIDs  += (CASE WHEN @ExtraFieldIDs   = '' THEN '' ELSE ' or ' END) 
									+ ' '', '' + bm.BranchIDs + '',''   like ''%, ' + CAST(value  AS VARCHAR(120)) + ',%''' 
									--+ ' '', '' + bm.BranchIDs + '',''   like '', ' + CAST(value  AS VARCHAR(120)) + '%,''' 

										FROM dbo.fn_Split(@BranchID,',')  
	PRINT(@ExtraFieldIDs)
	if (@mode = 1)
	begin
		DECLARE @PageStart int
		DECLARE @PageEnd int
		if (@PageNo <> 0)
		begin	
			set @PageStart = ((@PageNo -1) * @PageSize) +1
			set @PageEnd  = (@PageNo * @PageSize)
		end
		else
		begin
			set @PageStart = 1
			set @PageEnd = 1* @PageSize
		END
 -- 	DECLARE @ExtraFieldIDs VARCHAR(MAX) = ''
	--SELECT @ExtraFieldIDs  += (CASE WHEN @ExtraFieldIDs   = '' THEN '' ELSE ' or ' END) 
	--								+ ' '', '' + bm.BranchIDs + '',''   like ''%, ' + CAST(value  AS VARCHAR(120)) + ',%,''' 
	--								--+ ' '', '' + bm.BranchIDs + '',''   like '', ' + CAST(value  AS VARCHAR(120)) + '%,''' 

	--									FROM dbo.fn_Split(@BranchID,',')  
	--PRINT(@ExtraFieldIDs)
 -- 	DECLARE @ExtraFieldIDs VARCHAR(MAX) = ''
	--SELECT @ExtraFieldIDs  += (CASE WHEN @ExtraFieldIDs   = '' THEN '' ELSE ' or ' END) 
	--								--+ ' '', '' + bm.BranchIDs + '',''   like ''%, ' + CAST(value  AS VARCHAR(120)) + '%,''' 
	--								+'CHARINDEX('', '+ CAST(value  AS VARCHAR(120))+','','',''+bm.BranchIDs+'','')'+' > 0'
	--									FROM dbo.fn_Split(@BranchID,',')  
	--PRINT(@ExtraFieldIDs)
DECLARE @MainQuery nVARCHAR(max)=''
SET @MainQuery  += '		
		;with A AS
		(
		select sm.*,COUNT(*) OVER () AS TotalCount,
					ROW_NUMBER() OVER(ORDER BY '+
				
				case 
				when @SortBy='price' AND @sortmode='' then 'sm.pro_min_price  asc' 
				when @SortBy='price' AND @sortmode='desc' then 'sm.pro_min_price  desc' 
				when @SortBy='new' AND @sortmode='' then 'sm.pro_add_date  asc' 
				when @SortBy='new' AND @sortmode='desc' then 'sm.pro_add_date  desc' 
				--when @SortBy='discount' AND @sortmode='asc' then 'sm.pro_min_price end asc' 
				--when @SortBy='discount' AND @sortmode='desc' then 'sm.pro_min_price end asc' 
				when @SortBy='discount' AND @sortmode='' then 'disc_prc  asc' 
				when @SortBy='discount' AND @sortmode='desc' then 'disc_prc  desc' 
				when (@SortBy='' or @sortmode = '') then 'sm.pro_add_date desc ' end + '
					,sm.lot_srno,sm.color 
					)
				as Row,
				substring((select  '','' + bmsize.pro_size from store_stock as bmsize
					where sm.master_id = bmsize.master_id and pro_pcs > 0  
							order by case when ISNUMERIC(pro_size) = 1 then CONVERT(varchar(20),pro_size) else pro_size end
						FOR XML PATH('''')),2,1000000000)AS pro_size
						from
			
		(
			SELECT *  FROM 
			(
				select s.master_id,s.pro_name,s.pro_se_name,s.pro_add_date,s.color,s.pro_image,s.pro_more_image_1,s.pro_more_image_2,s.pro_more_image_3,s.pro_more_image_4,s.pro_more_image_5,s.coit_code,pro_is_in_new_arrivals,required_size,i.dept_id
					,sum(bm.pro_pcs) as stok_qty,
					 min(case when bm.pro_pcs > 0 then bm.pro_sale_price end)  as pro_min_price 
					,max(case when bm.pro_pcs > 0 then bm.pro_sale_price end) as pro_max_price,
					 max(case when bm.pro_pcs > 0 then bm.pro_price else 0 end) as pro_price
					,max(case when bm.pro_pcs > 0 then dbo.fn_GetDiscountAmt(bm.pro_price,bm.pro_sale_price) end) as disc_amt
					,max(case when bm.pro_pcs > 0 then dbo.fn_GetDiscountPrc(bm.pro_price,bm.pro_sale_price) end) as disc_prc
					,s.artical_no,s.lot_srno
					--I.dept_id,dept.dept_name,s.pro_is_in_new_arrivals,s.pro_is_in_best_sellers,s.pro_style as pro_style,
					--st.style_name,b.product_display_order,b.brand_name,s.coit_code,s.pro_is_in_recommend,dept.required_size
					
			from store_master as s 
			left join store_stock as bm on bm.master_id=s.master_id
			left join item_master as I on s.item_id=I.item_id
			left join brand_master as B on b.brand_id=i.brand_id
			inner join dept_master as dept on  I.dept_id = dept.dept_id
			left join style_master as st on s.pro_style = st.style_id
	where s.is_active = 1 and
				bm.pro_pcs > 0 
		'+ dbo.fn_AppendNonZeroValue (@minPrice,' AND bm.pro_sale_price >= @minPrice') + '
		'+ dbo.fn_AppendNonZeroValue (@maxPrice,' AND bm.pro_sale_price <= @maxPrice') + '
		'+ case when @minDiscount =0  then '' else 'and (dbo.fn_GetDiscountPrc(bm.pro_price,bm.pro_sale_price)) >= @minDiscount	'  END +'		  	
		'+ case when @maxDiscount =0  then '' else 'and (dbo.fn_GetDiscountPrc(bm.pro_price,bm.pro_sale_price)) <= @maxDiscount ' END  +'		  	
		'+ dbo.fn_AppendNonBlankValue (@dept_id ,' AND I.dept_id IN (select value from dbo.fn_split(@dept_id,'',''))') + '
		'+CASE WHEN @item_id=0 THEN '' WHEN @item_id='' THEN '' ELSE 'i.item_id=@item_id' END+'
		'+ dbo.fn_AppendNonBlankValue (@brand_id ,' AND I.brand_id IN (select value from dbo.fn_split(@brand_id,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (@prod_id ,' AND I.prod_id IN (select value from dbo.fn_split(@prod_id,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (@product_ids ,' AND i.prod_id IN (select value from dbo.fn_split(@product_ids,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@OccassionName),' AND s.OccasionName IN (select value from dbo.fn_split(@OccassionName,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@color),' AND s.color IN (select value from dbo.fn_split(@color,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@size),' AND bm.pro_size IN (select value from dbo.fn_split(@size,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (@style_id ,' AND s.pro_style IN (select value from dbo.fn_split(@style_id,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@coit_code),' AND s.coit_code IN (select value from dbo.fn_split(@coit_code,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@lot_srno),' AND s.lot_srno IN (select value from dbo.fn_split(@lot_srno,'',''))') + '
		'+CASE WHEN @pro_is_in_homepage=0 THEN '' ELSE 'AND s.pro_is_in_homepage=@pro_is_in_homepage' END+'
		'+CASE WHEN @pro_is_in_new_arrivals=0 THEN '' ELSE 'AND s.pro_is_in_new_arrivals=@pro_is_in_new_arrivals' END+'
		'+CASE WHEN @pro_is_in_best_sellers=0 THEN '' ELSE 'AND s.pro_is_in_best_sellers=@pro_is_in_best_sellers' END+'
		'+CASE WHEN @pro_is_in_pick_of_week=0 THEN '' ELSE 'AND s.pro_is_in_pick_of_week=@pro_is_in_pick_of_week' END+'
		'+CASE WHEN @pro_is_in_recommend=0 THEN '' ELSE 'AND s.pro_is_in_recommend=@pro_is_in_recommend' END+'
		'+CASE WHEN @pro_is_in_feature=0 THEN '' ELSE 'AND s.pro_is_in_feature=@pro_is_in_feature' END+'

		'+ case when @only_discounted_items =0  then '' else 'and dbo.fn_GetDiscountAmt(bm.pro_price,bm.pro_sale_price)>0 ' end+ '	
		'+CASE WHEN @not_in_master_id =0 THEN '' ELSE 'AND s.master_id !=@not_in_master_id ' end+'
		'+CASE WHEN @pro_is_in_sale =0 THEN '' ELSE 'AND (s.pro_price != 0 and s.pro_sale_price != s.pro_price)' end+'
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@HellType),' AND s.HellType IN (select value from dbo.fn_split(@HellType,'',''))') + '
		'+ dbo.fn_AppendNonBlankValue (dbo.fn_GetQuotedString(@UpperMaterial),' AND s.UpperMaterial IN (select value from dbo.fn_split(@UpperMaterial,'',''))') + '
    	'+ case when @SearchText    = '' then '' else ' and (s.pro_name  like ''%'' + @SearchText+ ''%'' or s.lot_srno like ''%'' + @SearchText + ''%'' or b.brand_name like ''%'' + @SearchText +''%'' or s.artical_no like ''%''+ @SearchText +''%'' or s.coit_code like ''%''+ @SearchText+''%''
														or (convert(varchar(20), s.master_id) like '''' + @SearchText +''%''))'   end +'
		'+CASE WHEN @BranchID ='' THEN '' ELSE ' AND ('+ @ExtraFieldIDs+')' END+'
				group by s.master_id,s.pro_name,s.pro_se_name,s.pro_add_date,s.color,s.pro_image,s.pro_more_image_1,s.pro_more_image_2,s.pro_more_image_3,s.pro_more_image_4,s.pro_more_image_5,s.coit_code,pro_is_in_new_arrivals,required_size,i.dept_id,s.artical_no,s.lot_srno
					--s.master_id,s.pro_name,s.pro_se_name,s.pro_add_date,s.color,s.pro_image,pro_more_image_1,pro_more_image_2,pro_more_image_3,
					--pro_more_image_4,pro_more_image_5,s.pro_sale_price,s.pro_price,s.pro_discount_amt,s.pro_discount_prc,
					--I.dept_id,dept.dept_name,s.pro_is_in_new_arrivals,s.pro_is_in_best_sellers,s.pro_style ,st.style_name,b.product_display_order,b.brand_name,s.coit_code,s.pro_is_in_recommend,dept.required_size
			  
			) AS TABLE1 
		   ) 
		   as sm
				--group by master_id,pro_name,pro_se_name,pro_add_date,color,pro_image,pro_more_image_1,pro_sale_price,pro_price,pro_discount_amt,stok_qty,coit_code
				
			) SELECT *  
			from A  ' + case when @PageStart = 0 then '' else ' where Row between ' + CAST(@PageStart as varchar(120)) +  ' and '+ + CAST(@PageEnd as varchar(120)) end  +'
			
'	

PRINT (@MainQuery)
execute sp_executesql @MainQuery,N'@mode int,
	@PageNo int = 0,
	@PageSize int = 0,
	@item_id int = 0,
	@color varchar(max) ,
	@size varchar(max) ,
	@dept_id varchar(max) ,
	@prod_id varchar(max) ,
	@product_ids varchar(max) ,
	@brand_id varchar(max) ,
	@style_id varchar(max) ,
	@coit_code varchaR(max) ,
	@lot_srno varchar(max) ,
	@minPrice float ,
	@maxPrice float ,
	@minDiscount float ,
	@maxDiscount float ,
	@sortby varchar(10) ,
	@sortmode varchar(10) ,
	@master_id int,
	@searchText varchar(250) ,
	@pro_is_in_homepage bit ,
	@pro_is_in_new_arrivals bit ,
	@pro_is_in_best_sellers bit ,
	@pro_is_in_pick_of_week bit ,
	@pro_is_in_recommend bit ,
	@not_in_master_id int ,
	@pro_is_in_sale bit ,
	@only_discounted_items bit,
	@pro_is_in_feature bit ,
	@accessories_dept varchar(10) ,
	@OccassionName VARCHAR(255) ,
	@HellType VARCHAR(MAX) ,
	@UpperMaterial VARCHAR(max) ,
	@BranchID varchar(max) ',
	@mode = @mode ,
	@PageNo  = @PageNo ,
	@PageSize  = @PageSize ,
	@item_id  = @item_id ,
	@color  = @color ,
	@size  = @size ,
	@dept_id = @dept_id ,
	@prod_id  = @prod_id ,
	@product_ids = @product_ids ,
	@brand_id  = @brand_id ,
	@style_id  = @style_id ,
	@coit_code  = @coit_code ,
	@lot_srno = @lot_srno ,
	@minPrice  = @minPrice ,
	@maxPrice  = @maxPrice ,
	@minDiscount  = @minDiscount ,
	@maxDiscount  = @maxDiscount ,
	@sortby  = @sortby ,
	@sortmode  =@sortmode ,
	@master_id  =@master_id ,
	@searchText  = @searchText ,
	@pro_is_in_homepage = @pro_is_in_homepage ,
	@pro_is_in_new_arrivals  =@pro_is_in_new_arrivals ,
	@pro_is_in_best_sellers  =@pro_is_in_best_sellers  ,
	@pro_is_in_pick_of_week  = @pro_is_in_pick_of_week ,
	@pro_is_in_recommend = @pro_is_in_recommend ,
	@not_in_master_id = @not_in_master_id ,
	@pro_is_in_sale  = @pro_is_in_sale ,
	@only_discounted_items   = @only_discounted_items ,
	@pro_is_in_feature  = @pro_is_in_feature ,
	@accessories_dept  = @accessories_dept ,
	@OccassionName  =@OccassionName ,
	@HellType = @HellType ,
	@UpperMaterial  =@UpperMaterial ,
	@BranchID = @BranchID 

--EXEC (@MainQuery)
					
		--SELECT *FROM #TMP_STORE WHERE Row between @PageStart and @pageEnd  
						
	end
	
	/*Get list of colors*/
	else if (@mode = 2)
	begin
		select sm.color as pro_color,sum(pro_pcs) as stok_qty 
				from store_master as sm 
				inner join item_master as im on sm.item_id = im.item_id
				inner join store_stock as bm on sm.master_id = bm.master_id
				where sm.is_active = 1 
				AND bm.pro_pcs > 0 
				AND (@dept_id = '' or @dept_id = '0' or im.dept_id in (select value from fn_Split(@dept_id,',')) ) 
					and (@prod_id = '' or @prod_id = '0' or prod_id = @prod_id )
					and (@product_ids='' or @product_ids = '0' or prod_id = @product_ids)
			AND (@OccassionName =  '' OR sm.OccasionName = @OccassionName)
					and (@only_discounted_items=0 or dbo.fn_GetDiscountAmt(bm.pro_price,bm.pro_sale_price)>0)
					and (@brand_id='' or @brand_id = '0' or im.brand_id in (select value from fn_Split(@brand_id,',')))
					and (@style_id='' or sm.pro_style in (select value from fn_Split(@style_id,',')))
					and (sm.pro_name = '' or sm.pro_name like '%'+ @SearchText +'%') and bm.pro_pcs > 0
					group by sm.color
	end
		
	/*Get list of size*/
	else if (@mode = 3)
	begin
	    select pro_size,sum(pro_pcs) as stok_qty 
				from store_master as sm 
				inner join item_master as im on sm.item_id = im.item_id
				inner join store_stock as bm on sm.master_id = bm.master_id
				where sm.is_active = 1 
					AND bm.pro_pcs > 0 
					AND (@dept_id = '' or @dept_id = '0' or im.dept_id in (select value from fn_Split(@dept_id,',')) ) 
					and (@prod_id = '' or @prod_id = '0' or prod_id = @prod_id )
					and (@product_ids='' or @product_ids = '0' or prod_id = @product_ids)
			AND (@OccassionName =  '' OR sm.OccasionName = @OccassionName)
					and (@only_discounted_items=0 or dbo.fn_GetDiscountAmt(bm.pro_price,bm.pro_sale_price)>0)
					and (@brand_id='' or @brand_id = '0' or im.brand_id in (select value from fn_Split(@brand_id,',')))
					and (@color='' or sm.color in (select value from fn_Split(@color,',')))
					and (sm.pro_name = '' or sm.pro_name like '%'+ @SearchText +'%') and bm.pro_pcs > 0
					and (@style_id='' or sm.pro_style in (select value from fn_Split(@style_id,',')))

					group by pro_size
						order by case when ISNUMERIC(pro_size) = 1 then CONVERT(VARCHAR(20),pro_size) else pro_size end
				
	end
	
	/*Get Price Range*/
	else if(@mode= 4)
	begin
		  select max(bm.pro_sale_price) as max_price,min(bm.pro_sale_price) as min_price 
				from store_master as sm 
				inner join item_master as im on sm.item_id = im.item_id
				inner join store_stock as bm on sm.master_id = bm.master_id
				where sm.is_active = 1 
				AND bm.pro_pcs > 0 
				AND (@dept_id = '' or @dept_id = '0' or im.dept_id in (select value from fn_Split(@dept_id,',')) ) 
					and (@prod_id = '' or @prod_id = '0' or prod_id = @prod_id )
					and (@product_ids='' or @product_ids = '0' or prod_id = @product_ids)
			AND (@OccassionName =  '' OR sm.OccasionName = @OccassionName)
					and (@only_discounted_items=0 or dbo.fn_GetDiscountAmt(bm.pro_price,bm.pro_sale_price)>0)
					and (@brand_id='' or @brand_id = '0' or im.brand_id in (select value from fn_Split(@brand_id,',')))
					and (@color='' or sm.color in (select value from fn_Split(@color,',')))
					and (@size='' or bm.pro_size in (select value from fn_Split(@size,',')))
					and (@style_id='' or sm.pro_style in (select value from fn_Split(@style_id,',')))

					and (sm.pro_name = '' or sm.pro_name like '%'+ @SearchText +'%') 
					
	end
	
	/*Get all detail of perticular one product */
	else if (@mode = 5)
	begin
		DECLARE @DetailQuery nVARCHAR(max)=''
		SET @DetailQuery +='
				select sm.master_id,sm.pro_name,sm.pro_se_name,sm.pro_add_date,sm.color,sm.pro_image,brand.brand_image,sm.pro_more_image_1,sm.pro_more_image_2,sm.pro_more_image_3,sm.pro_more_image_4,sm.pro_more_image_5,sm.item_id,
					im.style_id as pro_style,brand.brand_id, brand.brand_name,pro.prod_name as category_name,sm.coit_code,
					sm.lot_srno,style.style_name,dept.dept_name,im.prod_id,im.dept_id,dept.required_size,sm.pro_description,video_name
					,sum(bm.pro_pcs) as stok_qty,
 					  min(case when bm.pro_pcs > 0 then bm.pro_sale_price end)  as pro_min_price 
					 ,max(case when bm.pro_pcs > 0 then bm.pro_sale_price end) as pro_max_price
					 ,max(case when bm.pro_pcs > 0 then bm.pro_price else 0 end) as pro_price
					 ,max(case when bm.pro_pcs > 0 then  dbo.fn_GetDiscountAmt(bm.pro_price,bm.pro_sale_price) end) as disc_amt
					 ,max(case when bm.pro_pcs > 0 then dbo.fn_GetDiscountPrc(bm.pro_price,bm.pro_sale_price) end) as disc_prc
					 ,sm.artical_no
					 ,count(bm.pro_size) as SizeCount  
					 ,sm.OccasionName
					 ,sm.ShoeType
					 ,sm.UpperMaterial 
					 ,sm.CountryofOrigin 
					 ,sm.HellType, sm.HeelHeight,sm.PageTitle,sm.MetaDesc
						from store_master as sm 
						inner join item_master as im on sm.item_id = im.item_id
						left join brand_master as brand on im.brand_id = brand.brand_id
						left join prod_master as pro on im.prod_id = pro.prod_id
						left join style_master as style on sm.pro_style = style.style_id
						inner join dept_master as dept  on im.dept_id = dept.dept_id
						left join store_stock as bm on sm.master_id = bm.master_id
						--LEFT JOIN dbo.mstExtraField AS occasion ON occasion.Type = 5 AND sm.OccasionName = occasion.ExtraFieldID
						--LEFT JOIN dbo.mstExtraField AS shoetype ON shoetype.Type = 1 AND sm.ShoeType = shoetype.ExtraFieldID
						--LEFT JOIN dbo.mstExtraField AS uppermat ON uppermat.Type = 2 AND sm.UpperMaterial = uppermat.ExtraFieldID
						--LEFT JOIN dbo.mstExtraField AS corigin ON corigin.Type = 3 AND sm.CountryofOrigin = corigin.ExtraFieldID
						--LEFT JOIN dbo.mstExtraField AS htype ON htype.Type = 4 AND sm.HellType = htype.ExtraFieldID

						where sm.master_id  = @master_id and sm.is_active = 1
									'+CASE WHEN @BranchID ='' THEN '' ELSE ' AND ('+ @ExtraFieldIDs+')' END+'
						group by sm.master_id,sm.pro_name,sm.pro_se_name,sm.pro_add_date,sm.color,sm.pro_image,brand.brand_image,sm.pro_more_image_1,sm.pro_more_image_2,sm.pro_more_image_3,sm.pro_more_image_4,sm.pro_more_image_5,sm.item_id,
							im.style_id ,brand.brand_id, brand.brand_name,pro.prod_name,sm.coit_code,
							sm.lot_srno,style.style_name,dept.dept_name,im.prod_id,im.dept_id,dept.required_size,sm.pro_description,video_name,sm.artical_no
								,sm.OccasionName,sm.PageTitle,sm.MetaDesc
					 ,sm.ShoeType
					 ,sm.UpperMaterial 
					 ,sm.CountryofOrigin 
					 ,sm.HellType
					 ,sm.HeelHeight
				
				
				select bm.pro_size,bm.pro_pcs  ,bm.pro_price,bm.pro_sale_price from store_master as sm 
					inner join store_stock as bm on sm.master_id = bm.master_id
						where sm.master_id = @master_id  and sm.is_active = 1
								'+CASE WHEN @BranchID ='' THEN '' ELSE ' AND ('+ @ExtraFieldIDs+')' END+'
								ORDER BY CAST(bm.pro_size AS DECIMAL(10,2)) 

				
				/*0 - available color*/
				SELECT DISTINCT a.master_id,a.color,a.pro_image,a.pro_se_name FROM dbo.store_master AS a
						INNER JOIN dbo.store_master AS b ON  a.item_id = b.item_id AND a.coit_code = b.coit_code  --AND a.lot_srno = b.lot_srno
						inner join store_stock as bm on bm.master_id = a.master_id
							WHERE b.master_id = @master_id  AND a.is_active = 1
								'+CASE WHEN @BranchID ='' THEN '' ELSE ' AND ('+ @ExtraFieldIDs+')' END+'
		'

		PRINT(@DetailQuery)
		--EXEC(@DetailQuery)
		execute sp_executesql @DetailQuery,N'@master_id int',@master_id=@master_id
	end
	
	else if(@mode = 6)
	begin	
		select bm.pro_size,bm.pro_pcs  as stok_qty,bm.pro_price,bm.pro_sale_price from store_master as sm 
			inner join store_stock as bm on sm.master_id = bm.master_id
				where sm.master_id = @master_id and sm.is_active = 1
	end
end





GO

