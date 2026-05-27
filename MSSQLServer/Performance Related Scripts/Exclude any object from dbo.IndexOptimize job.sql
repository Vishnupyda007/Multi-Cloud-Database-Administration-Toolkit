EXECUTE dbo.IndexOptimize

    @Databases = 'EDS_CURR_STG',

    @Entities = 'SCHEMAS_AND_TABLES',

    @ExcludeObject = 'EDS_CURR_STG.ESA_PS_RS_SO_LINE_STG_CURR',  -- exclude this table

    @FragmentationLow = NULL,

    @FragmentationMedium = 'INDEX_REORGANIZE',

    @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
 