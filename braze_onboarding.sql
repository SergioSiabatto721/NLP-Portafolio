create or replace table global_finances.braze_onboarding as (
  with
  users as (
    select
    *
    from (
      select
      case when trim(nullif(regexp_replace(external_user_id, '[0-9]'),''),'_') in ('CO','MX','BR','AR','CL','UY','PE') then trim(nullif(regexp_replace(external_user_id, '[0-9]'),''),'_') end as pais
      , user_id
      , case when pais is not null then nullif(regexp_replace(external_user_id, '[^0-9]'),'')::int end as external_user_id
      , row_number() over(partition by external_user_id order by veces desc) as maximo
      from (
        select
        distinct
        user_id
        , external_user_id
        , count(*) over(partition by user_id) as veces
        from (
          select
          user_id
          , coalesce(external_user_id
                     , lead(external_user_id) ignore nulls over (partition by user_id order by cast(\"TIME\" as timestamp))
                     , lag(external_user_id) ignore nulls over (partition by user_id order by cast(\"TIME\" as timestamp))
                    ) as external_user_id
          from braze.braze_events
        )
      )
    )
    having maximo=1
  )

  select
  u.user_id
  , u.external_user_id
  , canvas_id
  , canvas_variation_id
  , in_control_group
  , canvas_step_id
  , canvas_name
  , coalesce(convert_timezone(case when timezone='Asia/Yangon'
                                        then 'Asia/Bangkok'
                                    when timezone='Asia/Atyrau'
                                        then 'Asia/Baghdad'
                                    when timezone='Asia/Famagusta'
                                        then 'Asia/Gaza'
                                    when timezone='America/Punta_Arenas'
                                        then 'America/Recife'
                                else timezone
                              end,'America/Bogota',cast(\"TIME\" as timestamp)),_modified,_fivetran_synced) as created_at
  , split_part(split_part(split_part(_file,'event_type=users.',2),'/',1),'.',1) as type
  , split_part(split_part(split_part(_file,'event_type=users.',2),'/',1),'.',2) as type1
  , split_part(split_part(split_part(_file,'event_type=users.',2),'/',1),'.',-1) as type2
  , _file
  , case when be.canvas_name in ('New _Onboarding_CO feature 250119','New _Onboarding_CO SMS  030519','Onboarding_CO FINAL SMS  100519') then 'CO'
          when be.canvas_name in ('Onboarding_MX feature 250119','New _Onboarding_MX SMS  030519','Onboarding_MX_FINAL SMS 100519') then 'MX'
          when be.canvas_name in ('New _Onboarding_BR feature 270219','New _Onboarding_BR SMS  030519','Onboarding_BR _FINAL_SMS  100519') then 'BR'
          when be.canvas_name in ('V5-CORTO_OK - New _Onboarding_AR feature 250219','New _Onboarding_AR feature 020519','Onboarding_AR_FINAL SMS 040719') then 'AR'
          when be.canvas_name in ('New _Onboarding_CL feature 040319','New _Onboarding_CL SMS  060519','Onboarding_CL_FINAL SMS 100519') then 'CL'
          when be.canvas_name in ('New _Onboarding_UY feature 040319','New _Onboarding_UY SMS  060519','Onboarding_UY_FINAL SMS 100519') then 'UY'
          when be.canvas_name in ('New _Onboarding_PE feature 040319','New _Onboarding_PE SMS  060519','Onboarding_PE_FINAL_SMS  100519') then 'PE'
    end as pais_onboarding
  , u.pais as pais_user
  , case when canvas_variation_id in ('647bfa57-9717-40b6-9fbe-dcdb648b00c9',  
                                       '865ea530-0ffb-462f-a941-baaa663ca544', 
                                       '55b1d134-0e72-4cdc-a387-2083d9cf5cce', 
                                       'd1634030-517b-4b2b-87d4-5695f8c98128', 
                                       'bbaa5747-784f-4478-bd90-8bad574d107b', 
                                       '97f2f872-d043-4493-a3e5-6eda6174b513',
                                       '597de2ab-c39c-4402-a258-6d6734ae5ee0'  
                                     )
                  then 2 
          when canvas_step_id in  ('15fb056f-d42c-47e2-94ea-be77e1f50d26', 
                                   '567737f5-5ade-4571-bd3e-371c50732f08', 
                                   'eeb968af-9af5-487e-ace1-44a56cb972c6', 
                                   '2e6ec6d4-dbfc-4404-8046-ff9dfb68332a', 
                                   '7a270b99-b758-4deb-a876-eec7ebc7a22d', 
                                   'ad3947dc-4e8f-4178-b484-c6c236c23855', 
                                   '97809e04-e98d-41db-9f4b-62ef11980117') 
                   then 3 
          when canvas_step_id in ('29541206-941d-4743-bc24-52bbcb26dff6', 
                                  '29fc878f-a641-4cb6-86f8-3a003a042cba', 
                                  'eb1d7e7a-aa6b-4fc0-8351-3c0e8aa4dc0a', 
                                  '491bf2f9-2cb1-4d73-8e22-6c59c1342e0f',
                                  '363e9002-ee69-4413-be2d-8357c9643ab8', 
                                  '03fd875b-0d41-4abc-a5e4-729772c5726a', 
                                  '43749223-901e-4c90-9515-42573aa54023')
                  then 4    
          else 1 
    end as version
  from braze.braze_events be
  join users u on
  u.user_id = be.user_id
  where type in ('canvas','messages')
  and pais is not null
  and canvas_id is not null
);
